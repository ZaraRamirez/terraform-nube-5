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

variable "state_bucket_name" {
  description = "Nombre del bucket de estado. Si es null: <project>-tfstate-<account_id>"
  type        = string
  default     = null
}

variable "create_github_role" {
  description = "Crear el proveedor OIDC y el rol para GitHub Actions"
  type        = bool
  default     = true
}

variable "github_owner" {
  description = "Usuario u organizacion dueña del repositorio de GitHub"
  type        = string
  default     = "OWNER"
}

variable "github_repo" {
  description = "Nombre del repositorio de GitHub"
  type        = string
  default     = "REPO"
}

variable "github_oidc_provider_arn" {
  description = "ARN de un proveedor OIDC de GitHub ya existente en la cuenta (solo hay uno por cuenta). Si es null se crea."
  type        = string
  default     = null
}

variable "github_role_policy_arn" {
  description = "Politica gestionada que se adjunta al rol de GitHub Actions"
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}
