resource kubernetes_service_v1 redis_service {
  metadata {
    name      = "${var.name}-svc"
    namespace = var.k8s_namespace
    labels = local.labels
    annotations = {
      "cloud.google.com/neg" = jsonencode({ingress = true})
    }
  }

  spec {
    type             = "ClusterIP"
    port {
      name        = "redis"
      port        = 6379
      target_port = var.master_port
    }

    selector = local.labels
  }
}
