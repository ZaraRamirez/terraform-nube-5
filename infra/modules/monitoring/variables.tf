variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "alert_email" {
  description = "Correo que recibe las alertas (SNS pide confirmar la suscripcion)"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "server_service_name" {
  type = string
}

variable "worker_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "db_identifier" {
  type = string
}

variable "redis_cluster_id" {
  type = string
}

variable "log_group_name" {
  description = "Log group de CloudWatch donde se cuentan los ERROR"
  type        = string
}

variable "log_error_threshold" {
  description = "Lineas ERROR en 5 minutos a partir de las cuales se dispara la alarma"
  type        = number
  default     = 5
}
