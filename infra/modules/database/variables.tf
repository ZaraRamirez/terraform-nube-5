variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas para el subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de RDS"
  type        = string
}

variable "db_instance_class" {
  description = "Tipo de instancia de RDS PostgreSQL"
  type        = string
}
