variable "region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
  default     = "crm"
}

variable "twenty_image_tag" {
  description = "Version fija de la imagen twentycrm/twenty"
  type        = string
  default     = "v2.56.1"
}

variable "db_instance_class" {
  description = "Tipo de instancia de RDS PostgreSQL"
  type        = string
  default     = "db.t3.micro"
}

variable "redis_node_type" {
  description = "Tipo de nodo de ElastiCache Redis"
  type        = string
  default     = "cache.t3.micro"
}

variable "lab_role_arn" {
  description = "ARN de un rol IAM existente (ej. LabRole en AWS Academy). Si es null se crea uno."
  type        = string
  default     = null
}
