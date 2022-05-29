locals {
  display_app_name = "Mieszkania app"
}

resource "google_project_service" "iap_api" {
  service = "iap.googleapis.com"
}

resource "google_iap_brand" "app_brand" {
  support_email     = var.admins_email
  application_title = local.display_app_name
  depends_on = [google_project_service.iap_api]
}

resource "google_iap_client" "iap_client" {
  display_name = "${local.display_app_name} client"
  brand        =  google_iap_brand.app_brand.name
}

output "iap_client_client_id" {
  value = google_iap_client.iap_client.client_id
}

output "iap_client_client_secret" {
  value = google_iap_client.iap_client.secret
  sensitive = true
}
