resource "google_compute_global_address" "default" {
  name = "default-public-ip"
  description = "gke-global-ip"
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "mieszkania_app_cert" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "ManagedCertificate"
    "metadata" = {
      "name"      = "${local.app_name}-cert"
      "namespace" = var.k8s_namespace
    }
    "spec" = {
      "domains" = [var.domain]
    }
  }
}

resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "managed-cert-ingress"
    namespace = var.k8s_namespace

    annotations = {
      "kubernetes.io/ingress.class" = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates" = kubernetes_manifest.mieszkania_app_cert.manifest.metadata.name
      "app-deployment-version-hash" = base64sha256(jsonencode(kubernetes_deployment.app_deployment.spec))
    }
  }

  spec {
    default_backend {
      service {
        name = kubernetes_service_v1.app_service.metadata.0.name
        port {
          number = kubernetes_service_v1.app_service.spec.0.port.0.port
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.app_deployment]
}

resource "kubernetes_secret" "iap-secret" {
  metadata {
    name = "iap-secret"
    namespace = var.k8s_namespace
    labels = local.labels
  }

  data = {
    client_id     = google_iap_client.iap_client.client_id
    client_secret = google_iap_client.iap_client.secret
  }
}

resource "kubernetes_manifest" "iap-backend" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "iap-backend"
      namespace = var.k8s_namespace
    }
    spec = {
      iap = {
        enabled = true
        oauthclientCredentials = { secretName = kubernetes_secret.iap-secret.metadata.0.name }
      }
    }
  }
}
