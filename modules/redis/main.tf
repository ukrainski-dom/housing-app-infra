locals {
  labels = {
    "app.kubernetes.io/name"     = var.name
    "app.kubernetes.io/instance" = "${var.name}-instance"
  }

  default_resource_requests = {
    cpu    = "250m"
    memory = "500Mi"
  }
}


resource kubernetes_stateful_set redis_master {
  metadata {
    name      = "${var.name}-master"
    namespace = var.k8s_namespace
    labels = local.labels
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations["autopilot.gke.io/resource-adjustment"],
    ]
  }


  spec {
    selector {
      match_labels = local.labels
    }

    service_name = "${var.name}-master"

    template {
      metadata {
        labels = local.labels
        annotations = var.master_pod_annotations
      }

      spec {
        security_context {
          fs_group    = var.master_security_context["fs_group"]
          run_as_user = var.master_security_context["run_as_user"]
        }

        container {
          resources {
            requests = {
              cpu    = merge(local.default_resource_requests, var.master_resource_requests).cpu
              ephemeral-storage = "1Gi"
              memory = merge(local.default_resource_requests, var.master_resource_requests).memory
            }
          }

          name              = var.name
          image             = var.redis_image
          image_pull_policy = var.redis_image_pull_policy
          args              = var.master_args

          env {
            name  = "REDIS_REPLICATION_MODE"
            value = "master"
          }

          env {
            name = "REDIS_PASSWORD"

            value_from {
              secret_key_ref {
                name = var.name
                key  = "redis-password"
              }
            }
          }

          env {
            name  = "ALLOW_EMPTY_PASSWORD"
            value = var.use_password ? "no" : "yes"
          }

          env {
            name  = "REDIS_PORT"
            value = var.master_port
          }

          env {
            name  = "REDIS_DISABLE_COMMANDS"
            value = join(",", var.master_disable_commands)
          }

          env {
            name  = "REDIS_EXTRA_FLAGS"
            value = join(" ", var.master_extra_flags)
          }

          port {
            name           = "redis"
            container_port = var.master_port
          }

          liveness_probe {
            initial_delay_seconds = var.master_liveness_probe["initial_delay_seconds"]
            period_seconds        = var.master_liveness_probe["period_seconds"]
            timeout_seconds       = var.master_liveness_probe["timeout_seconds"]
            success_threshold     = var.master_liveness_probe["success_threshold"]
            failure_threshold     = var.master_liveness_probe["failure_threshold"]

            exec {
              command = [
                "redis-cli",
                "ping",
              ]
            }
          }

          readiness_probe {
            initial_delay_seconds = var.master_readiness_probe["initial_delay_seconds"]
            period_seconds        = var.master_readiness_probe["period_seconds"]
            timeout_seconds       = var.master_readiness_probe["timeout_seconds"]
            success_threshold     = var.master_readiness_probe["success_threshold"]
            failure_threshold     = var.master_readiness_probe["failure_threshold"]

            exec {
              command = [
                "redis-cli",
                "ping",
              ]
            }
          }
        }
      }
    }

    update_strategy {
      type = "RollingUpdate"
    }
  }
}
