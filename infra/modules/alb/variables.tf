variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  description = "Security group del ALB"
  type        = string
}
