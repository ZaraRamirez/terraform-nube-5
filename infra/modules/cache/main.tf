# Base de datos en memoria gestionada: cache, sesiones y cola de trabajos (BullMQ)
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-redis-subnets"
  subnet_ids = var.private_subnet_ids
}

# Twenty usa Redis como cola de trabajos: no se deben expulsar llaves
resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.project}-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [var.security_group_id]
  apply_immediately    = true
}
