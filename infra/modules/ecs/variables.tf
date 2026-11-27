variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "region" {
  type = string
}

variable "twenty_image" {
  description = "Imagen (repositorio:tag) de los contenedores server y worker"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  description = "Security group de las tareas ECS"
  type        = string
}

variable "target_group_arn" {
  description = "Target group del ALB para el server"
  type        = string
}

variable "alb_dns_name" {
  type = string
}

variable "redis_address" {
  type = string
}

variable "secret_arn" {
  description = "ARN del secreto con PG_DATABASE_URL, ENCRYPTION_KEY y APP_SECRET"
  type        = string
}
