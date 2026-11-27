output "identifier" {
  value = aws_db_instance.postgres.identifier
}

output "address" {
  value = aws_db_instance.postgres.address
}

output "db_name" {
  value = aws_db_instance.postgres.db_name
}

output "username" {
  value = aws_db_instance.postgres.username
}

output "password" {
  value     = random_password.db.result
  sensitive = true
}
