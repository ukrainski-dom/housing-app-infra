output "redis_url" {
  value = format("redis://%s:%s", kubernetes_service_v1.redis_service.metadata.0.name, kubernetes_service_v1.redis_service.spec.0.port.0.port)
  description = "Redis connection string"
}
