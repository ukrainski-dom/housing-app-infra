terraform {
  backend "gcs" {}
}

locals {
  k8s_namespace = "default"
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

module "db" {
  source        = "../../modules/db"
  instance_name = "mieszkania-app-db-instance"
  region        = var.region
  zone          = var.zone
}

module "gke" {
  source       = "../../modules/gke"
  cluster_name = "mieszkania-app-cluster"
  project = var.project
  region       = var.region
  depends_on   = [module.db]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.k8s_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.k8s_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${module.gke.k8s_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.k8s_ca_certificate)
  load_config_file       = false
}

module "redis" {
  source        = "../../modules/redis"
  use_password  = false
  k8s_namespace = local.k8s_namespace
  depends_on    = [module.gke]
}

locals {
  repo_loc = "europe-central2"
  repo_id  = "apps"
  repo_url = "${local.repo_loc}-docker.pkg.dev/${var.project}/${local.repo_id}"
}

resource "google_artifact_registry_repository" "docker_registry" {
  provider      = google-beta
  location      = local.repo_loc
  repository_id = local.repo_id
  format        = "DOCKER"
}

data "google_compute_default_service_account" "default" {}

resource "google_artifact_registry_repository_iam_member" "registry_iam" {
  provider   = google-beta
  location   = google_artifact_registry_repository.docker_registry.location
  repository = google_artifact_registry_repository.docker_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

module "app" {
  source           = "../../modules/mieszkania_app_k8s"
  domain           = var.domain
  admins_email     = var.admins_email
  docker_image     = "${local.repo_url}/${var.docker_image}"
  db_instance_name = module.db.db_instance_name
  gke_cluster_name = module.gke.k8s_name
  redis_url        = module.redis.redis_url
  k8s_namespace    = local.k8s_namespace
  project = var.project
  region = var.region
  depends_on       = [module.db, module.redis, module.gke, google_artifact_registry_repository.docker_registry]
}
