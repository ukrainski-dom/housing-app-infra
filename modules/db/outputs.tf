output "db_instance_name" {
  value       = google_sql_database_instance.postgres.name
  description = "Postgresql instance name"
}
