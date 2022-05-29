variable name {
  description = "A user specified descriptor of this deployment"
  default     = "redis"
}

variable redis_image {
  description = "Redis docker image"
  default = "docker.io/bitnami/redis:6.2"
}

variable redis_image_pull_policy {
  description = "One of Always, Never, IfNotPresent. Defaults to Always if :latest tag is specified, or IfNotPresent otherwise."
  default     = "IfNotPresent"
}

variable use_password {
  description = "Set to 'false' to disable password protected access to redis."
  default     = true
}

variable password {
  description = <<EOF
Redis password (both master and slave)
Defaults to a random 10-character alphanumeric string if not set and usePassword is true
EOF

  default = ""
}

variable "k8s_namespace" {
  default     = "default"
  description = "k8s target namespace"
}

variable master_port {
  default = "6379"
}

variable master_args {
  type = list

  description = <<EOF
Redis command arguments.
Can be used to specify command line arguments, for example:

master_args = [
 "redis-server",
 "--maxmemory-policy volatile-ttl"
]
EOF

  default = []
}

variable master_extra_flags {
  type = list

  description = <<EOF
 Redis additional command line flags
 Can be used to specify command line flags, for example:

 redisExtraFlags = [
  "--maxmemory-policy volatile-ttl",
 ]
EOF

  default = []
}

variable master_disable_commands {
  type = list

  description = <<EOF
Comma-separated list of Redis commands to disable
Can be used to disable Redis commands for security reasons.
ref: https://github.com/bitnami/bitnami-docker-redis#disabling-redis-commands
EOF

  default = [
    "FLUSHDB",
    "FLUSHALL",
  ]
}

variable master_resource_requests {
  type = map

  description = <<EOF
Redis Master resource requests
ref: http://kubernetes.io/docs/user-guide/compute-resources/
  master_resource_requests = {
    memory = "256Mi"
    cpu = "100m"
  }
EOF

  default = {}
}

variable master_resource_limits {
  type = map

  description = <<EOF
Redis Master resource limits
ref: http://kubernetes.io/docs/user-guide/compute-resources/
  master_resource_limits = {
    memory = "256Mi"
    cpu = "100m"
  }
EOF

  default = {}
}

variable master_liveness_probe {
  description = "Redis Master Liveness Probe configuration"

  default = {
    enabled               = true
    initial_delay_seconds = 30
    period_seconds        = 10
    timeout_seconds       = 5
    success_threshold     = 1
    failure_threshold     = 5
  }
}

variable master_readiness_probe {
  description = "Redis Master Readiness Probe configuration"

  default = {
    enabled               = true
    initial_delay_seconds = 30
    period_seconds        = 10
    timeout_seconds       = 5
    success_threshold     = 1
    failure_threshold     = 5
  }
}

variable master_pod_annotations {
  type    = map
  default = {}
}

variable master_security_context {
  default = {
    enabled     = true
    fs_group    = 1001
    run_as_user = 1001
  }
}
