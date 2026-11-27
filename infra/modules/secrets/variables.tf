variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "db_address" {
  description = "Endpoint de PostgreSQL"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
}

variable "db_password" {
  description = "Contrasena de la base de datos"
  type        = string
  sensitive   = true
}
