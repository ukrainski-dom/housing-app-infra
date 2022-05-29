output "k8s_name" {
  value       = google_container_cluster.gke-cluster.name
  description = "Cluster name"
}

output "k8s_endpoint" {
  value       = google_container_cluster.gke-cluster.endpoint
  description = "Cluster endpoint"
}

output "k8s_ca_certificate" {
  value       = google_container_cluster.gke-cluster.master_auth[0].cluster_ca_certificate
  description = "Cluster CA certificate"
}
