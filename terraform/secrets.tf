# Twenty mete la clave tal cual en la URL de conexion: sin caracteres especiales
resource "random_password" "db" {
  length  = 32
  special = false
}

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
    PG_DATABASE_URL = "postgres://${aws_db_instance.postgres.username}:${random_password.db.result}@${aws_db_instance.postgres.address}:5432/${aws_db_instance.postgres.db_name}"
    ENCRYPTION_KEY  = random_password.encryption_key.result
    APP_SECRET      = random_password.encryption_key.result
  })
}
