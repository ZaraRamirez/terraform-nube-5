output "crm_url" {
  description = "URL publica del CRM"
  value       = local.server_url
}

output "rds_endpoint" {
  description = "Endpoint de PostgreSQL (privado)"
  value       = aws_db_instance.postgres.address
}

output "redis_endpoint" {
  description = "Endpoint de Redis (privado)"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "ecs_cluster" {
  value = aws_ecs_cluster.main.name
}

output "log_group" {
  value = aws_cloudwatch_log_group.twenty.name
}
