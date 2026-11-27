variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se crean los security groups"
  type        = string
}
