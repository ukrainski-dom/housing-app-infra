locals {
  app_name = "mieszkania-app"
  labels = {
    "app.kubernetes.io/name"     = local.app_name
    "app.kubernetes.io/instance" = "${local.app_name}-instance"
  }
}

resource "google_service_account" "cloudsql-proxy-sa" {
  account_id   = "cloudsql-proxy-sa"
  display_name = "CloudSQL proxy account"
}

resource "google_service_account_key" "cloudsql-proxy-sa-key" {
  service_account_id = google_service_account.cloudsql-proxy-sa.name
}

resource "google_project_service" "sqladmin_api" {
  service = "sqladmin.googleapis.com"
}

resource "google_project_iam_member" "cloudsql-proxy-sa-iam" {
  project = var.project
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.cloudsql-proxy-sa.email}"
  depends_on = [google_project_service.sqladmin_api]
}

resource "random_password" "app_user_db_pass" {
  length           = 30
  special          = false
}

data "google_sql_database_instance" "db_instance" {
  name = var.db_instance_name
}

resource "google_sql_database" "app_database" {
  charset   = "UTF8"
  collation = "en_US.UTF8"
  name     = local.app_name
  instance = data.google_sql_database_instance.db_instance.name
}

resource "google_sql_user" "database_user" {
  name     = local.app_name
  instance = data.google_sql_database_instance.db_instance.name
  password = random_password.app_user_db_pass.result
}

output "app_user_db_pass" {
  value     = random_password.app_user_db_pass.result
  sensitive = true
}

resource "random_password" "mieszkania-app-secret" {
  upper = false
  override_special = "!@#$%^&*(-_=+)"
  length = 50
}

output "mieszkania-app-secret" {
  value     = random_password.mieszkania-app-secret.result
  sensitive = true
}

data "google_secret_manager_secret_version" sentry-io-dns-url {
  secret = "sentry-io-dns-url"
}

resource "kubernetes_secret" "app_init_secret" {
  metadata {
    name      = "${local.app_name}-init-secret"
    namespace = var.k8s_namespace
    labels    = local.labels
  }

  data = {
    DJANGO_SECRET_KEY   = random_password.mieszkania-app-secret.result
    DATABASE_URL = "postgres://${google_sql_user.database_user.name}:${random_password.app_user_db_pass.result}@${data.google_sql_database_instance.db_instance.private_ip_address}:5432/${google_sql_database.app_database.name}"
    SENTRY_DSN   = data.google_secret_manager_secret_version.sentry-io-dns-url.secret_data
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "${local.app_name}-secret"
    namespace = var.k8s_namespace
    labels    = local.labels
  }

  data = {
    DJANGO_SECRET_KEY   = random_password.mieszkania-app-secret.result
    DATABASE_URL = "postgres://${google_sql_user.database_user.name}:${random_password.app_user_db_pass.result}@127.0.0.1:5432/${google_sql_database.app_database.name}"
    SENTRY_DSN   = data.google_secret_manager_secret_version.sentry-io-dns-url.secret_data
  }
}

resource "kubernetes_secret" "cloudsql-proxy-credentials" {
  metadata {
    name      = "cloudsql-instance-credentials"
    namespace = var.k8s_namespace
    labels    = local.labels
  }

  data = {
    "credentials.json" = base64decode(google_service_account_key.cloudsql-proxy-sa-key.private_key)
  }
}
