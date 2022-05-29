data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name = "default"
  region = var.region
}


resource "google_container_cluster" "gke-cluster" {
  name = var.cluster_name

  location = var.region
  enable_autopilot = true

  release_channel {
    channel = "REGULAR"
  }

#  network = data.google_compute_network.default.self_link
  network = "projects/mieszkania-app-prod/global/networks/default"
#  subnetwork = data.google_compute_subnetwork.default.self_link
  subnetwork = "projects/mieszkania-app-prod/regions/europe-central2/subnetworks/default"

  ip_allocation_policy {
    cluster_ipv4_cidr_block = "/17"
    services_ipv4_cidr_block = "/22"
  }

  initial_node_count       = 1

  node_config {
    disk_size_gb = 100
  }
}
