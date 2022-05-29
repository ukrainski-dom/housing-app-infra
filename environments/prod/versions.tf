terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.22.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.22.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.7.0"
    }
  }
  required_version = "~> 1.1"
}