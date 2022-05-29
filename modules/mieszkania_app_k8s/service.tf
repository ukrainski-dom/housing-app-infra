data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = var.region
}

resource "kubernetes_service_v1" "app_service" {
  metadata {
    name      = "${local.app_name}-service"
    namespace = var.k8s_namespace
    labels    = local.labels
    annotations = {
      "cloud.google.com/backend-config" = jsonencode({
        default = kubernetes_manifest.iap-backend.manifest.metadata.name
      })
      "cloud.google.com/neg" = jsonencode({ ingress = true })
    }
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations["cloud.google.com/neg-status"]
    ]
  }

  spec {
    type     = "ClusterIP"
    selector = local.labels
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = local.app_container_port_name
    }
  }
}

