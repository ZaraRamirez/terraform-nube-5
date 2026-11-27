variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas para el subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de Redis"
  type        = string
}

variable "redis_node_type" {
  description = "Tipo de nodo de ElastiCache Redis"
  type        = string
}
