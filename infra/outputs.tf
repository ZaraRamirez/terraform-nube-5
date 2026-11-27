output "crm_url" {
  description = "URL publica del CRM"
  value       = module.ecs.server_url
}

output "rds_endpoint" {
  description = "Endpoint de PostgreSQL (privado)"
  value       = module.database.address
}

output "redis_endpoint" {
  description = "Endpoint de Redis (privado)"
  value       = module.cache.address
}

output "ecs_cluster" {
  value = module.ecs.cluster_name
}

output "log_group" {
  value = module.ecs.log_group_name
}

output "twenty_image" {
  description = "Imagen desplegada"
  value       = var.twenty_image
}

output "dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = module.monitoring.dashboard_url
}
