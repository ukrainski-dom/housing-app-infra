locals {
  app_container_port_name = "http"
  app_container_port_number = "8080"
  app_container_health_check_path = "healthz/"
}

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "mieszkania-app-config"
    namespace   = var.k8s_namespace
    labels      = local.labels
  }
  data = {
    HOST = "0.0.0.0"
    PORT = local.app_container_port_number
    WEB_CONCURRENCY = "10"
    DJANGO_SETTINGS_MODULE = "config.settings.production"
    REDIS_URL = var.redis_url
    DJANGO_ALLOWED_HOSTS = var.domain
    RENDER_EXTERNAL_HOSTNAME = var.domain
    BASE_URL = var.domain
    DJANGO_ADMIN_URL = "admin/"
    MAILGUN_DOMAIN = "none"
    MAILGUN_API_KEY = "none"
    DJANGO_SECURE_SSL_REDIRECT = "False"
  }
}

resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = "${local.app_name}"
    namespace = var.k8s_namespace
    labels    = local.labels
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations["autopilot.gke.io/resource-adjustment"],

      # gke-spot instance values, provided by GCP
      spec.0.template.0.metadata.0.annotations["autopilot.gke.io/selector-toleration"],
      spec.0.template.0.spec.0.toleration
    ]
  }

  wait_for_rollout = false

  spec {
    replicas = 1
    strategy { type = "RollingUpdate" }

    selector {
      match_labels = local.labels
    }

    template {
      metadata { labels = local.labels }
      spec {
        security_context {
          fs_group = 33
          seccomp_profile { type = "RuntimeDefault" }
        }

        init_container {
          name = "run-migrations"
          image = var.docker_image
          image_pull_policy = "Always"
          command = ["python",  "manage.py", "migrate"]
          env_from {
            secret_ref { name = kubernetes_secret.app_init_secret.metadata.0.name }
          }
          env_from {
            config_map_ref { name = kubernetes_config_map.app_config.metadata.0.name }
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "500M"
            }
            requests = {
              cpu    = "500m"
              memory = "500M"
            }
          }
        }

        container {
          name              = local.app_name
          image             = var.docker_image
          image_pull_policy = "Always"
          command = ["gunicorn", "config.wsgi:application", "-t", "60"]

          port {
            name           = local.app_container_port_name
            container_port = local.app_container_port_number
            protocol       = "TCP"
          }

          env_from {
            secret_ref { name = kubernetes_secret.app_secret.metadata.0.name }
          }

          env_from {
            config_map_ref { name = kubernetes_config_map.app_config.metadata.0.name }
          }

          resources {
            limits = {
              cpu    = "1"
              ephemeral-storage = "500M"
              memory = "2G"
            }
            requests = {
              cpu    = "1.0"
              ephemeral-storage = "500M"
              memory = "2G"
            }
          }

          startup_probe {
            http_get {
              path        = local.app_container_health_check_path
              port        = local.app_container_port_name
              http_header {
                name  = "Host"
                value = var.domain
              }
            }
            failure_threshold = 40
            period_seconds    = 15
          }
          liveness_probe {
            http_get {
              path        = local.app_container_health_check_path
              port        = local.app_container_port_name
              http_header {
                name  = "Host"
                value = var.domain
              }
            }
            period_seconds    = 10
            timeout_seconds   = 15
            success_threshold = 1
            failure_threshold = 6
          }
          readiness_probe {
            http_get {
              path        = local.app_container_health_check_path
              port        = local.app_container_port_name
              http_header {
                name  = "Host"
                value = var.domain
              }
            }
            period_seconds    = 30
            timeout_seconds   = 15
            success_threshold = 1
            failure_threshold = 6
          }
        }

        container {
          name    = "cloudsql-proxy"
          image   = "gcr.io/cloudsql-docker/gce-proxy:1.30.1"
          command = [
            "/cloud_sql_proxy", "-instances=${data.google_sql_database_instance.db_instance.connection_name}=tcp:5432",
            "-credential_file=/secrets/cloudsql/credentials.json", "-verbose=false"
          ]

          resources {
            limits = {
              cpu    = "500m"
              ephemeral-storage = "500M"
              memory = "128M"
            }
            requests = {
              cpu    = "500m"
              ephemeral-storage = "500M"
              memory = "128M"
            }
          }

          volume_mount {
            name       = "cloudsql-instance-credentials"
            read_only  = true
            mount_path = "/secrets/cloudsql"
          }
        }

        termination_grace_period_seconds = 25

        volume {
          name = "cloudsql-instance-credentials"
          secret { secret_name = kubernetes_secret.cloudsql-proxy-credentials.metadata.0.name }
        }
      }
    }
  }
  depends_on = [google_project_iam_member.cloudsql-proxy-sa-iam]
}

