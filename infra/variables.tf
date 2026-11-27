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

variable "twenty_image" {
  description = "Imagen de Docker Hub para server y worker de Twenty (se cambia por PR en env/prod.tfvars)"
  type        = string
  default     = "twentycrm/twenty:v2.56.1"
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

variable "alert_email" {
  description = "Correo que recibe las alertas de CloudWatch via SNS"
  type        = string
}

variable "log_error_threshold" {
  description = "Lineas ERROR en 5 minutos a partir de las cuales se dispara la alarma"
  type        = number
  default     = 5
}
