variable "k8s_namespace" {
  default     = "default"
  description = "k8s target namespace"
}

variable "domain" {
  description = "App domain"
}

variable "db_instance_name" {
  description = "Postgrsql instance name"
}

variable "gke_cluster_name" {
  description = "GKE cluster name"
}

variable "redis_url" {
  description = "Redis url"
}

variable "admins_email" {
  description = "email to admins"
}

variable "docker_image" {
  description = "App docker image"
}

variable "project" {
  description = "GCP project"
}

variable "region" {
  description = "GCP region"
}

