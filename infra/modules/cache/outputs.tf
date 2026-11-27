output "cluster_id" {
  value = aws_elasticache_cluster.redis.cluster_id
}

output "address" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
