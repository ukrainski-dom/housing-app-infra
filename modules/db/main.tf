data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "peering-ip-block" {
  name          = "private-ip-block"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 24
  network       = data.google_compute_network.default.id
}

resource "google_service_networking_connection" "vpc-connection" {
  network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.peering-ip-block.name]
}

resource "google_sql_database_instance" "postgres" {
  name                = var.instance_name
  region              = var.region
  database_version    = "POSTGRES_13"
  deletion_protection = true

  settings {
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"

    backup_configuration {
      backup_retention_settings {
        retained_backups = "7"
        retention_unit   = "COUNT"
      }
      enabled                        = true
      location                       = "eu"
      point_in_time_recovery_enabled = "true"
      start_time                     = "01:00"
      transaction_log_retention_days = "7"
    }

    database_flags {
      name  = "max_connections"
      value = "50"
    }

    database_flags {
      name  = "track_activity_query_size"
      value = "16384"
    }

    disk_autoresize       = true
    disk_autoresize_limit = "0"
    disk_size             = "10"
    disk_type             = "PD_SSD"

    insights_config {
      query_insights_enabled  = "true"
      query_string_length     = "1024"
      record_application_tags = "false"
      record_client_address   = "false"
    }

    ip_configuration {
      authorized_networks {
        name  = "Google Data Studio 1"
        value = "142.251.74.0/23"
      }

      authorized_networks {
        name  = "Google Data Studio 2"
        value = "74.125.0.0/16"
      }

      ipv4_enabled    = true
      private_network = data.google_compute_network.default.id
      require_ssl     = false
    }

    location_preference {
      zone = var.zone
    }

    maintenance_window {
      day  = 7
      hour = 2
    }

    tier = "db-f1-micro"
  }

  depends_on = [google_service_networking_connection.vpc-connection]
}
