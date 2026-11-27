resource "random_password" "encryption_key" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "twenty" {
  name                    = "${var.project}-twenty-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "twenty" {
  secret_id = aws_secretsmanager_secret.twenty.id
  secret_string = jsonencode({
    PG_DATABASE_URL = "postgres://${var.db_username}:${var.db_password}@${var.db_address}:5432/${var.db_name}"
    ENCRYPTION_KEY  = random_password.encryption_key.result
    APP_SECRET      = random_password.encryption_key.result
  })
}
