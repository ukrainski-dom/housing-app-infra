resource random_string redis_password {
  count   = var.use_password ? 1 : 0
  special = false
  length  = 10
}

resource kubernetes_secret redis {
  metadata {
    name      = var.name
    namespace = var.k8s_namespace
    labels = local.labels
  }

  data = {
    redis-password = trimspace(coalesce(var.password, join("", random_string.redis_password.*.result), " "))
  }

  type = "Opaque"
}

