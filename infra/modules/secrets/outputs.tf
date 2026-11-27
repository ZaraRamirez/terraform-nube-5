output "secret_arn" {
  description = "ARN del secreto (la version ya esta creada al evaluarse este output)"
  value       = aws_secretsmanager_secret.twenty.arn
  depends_on  = [aws_secretsmanager_secret_version.twenty]
}
