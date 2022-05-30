locals {
  network_id = "projects/${var.project}/global/networks/default"
  subnetwork_id = "projects/${var.project}/regions/${var.region}/subnetworks/default"
}

resource "google_compute_router" "gke_router" {
  name    = "my-router"
  region  = var.region
  network = local.network_id
}

resource "google_compute_router_nat" "gke_nat" {
  name                               = "gke-nat"
  router                             = google_compute_router.gke_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_container_cluster" "gke-cluster" {
  name = var.cluster_name

  location = var.region
  enable_autopilot = true

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
  }

  release_channel {
    channel = "REGULAR"
  }

  network = local.network_id
  subnetwork = local.subnetwork_id

  ip_allocation_policy {
    cluster_ipv4_cidr_block = "/17"
    services_ipv4_cidr_block = "/22"
  }

  initial_node_count       = 1

  node_config {
    disk_size_gb = 100
  }
}
