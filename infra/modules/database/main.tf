# Twenty mete la clave tal cual en la URL de conexion: sin caracteres especiales
resource "random_password" "db" {
  length  = 32
  special = false
}

# Base de datos relacional gestionada: empresas, contactos, oportunidades, etc.
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project}-db-subnets"
  subnet_ids = var.private_subnet_ids
}

# PostgreSQL 16 en RDS obliga SSL por defecto; Twenty se conecta sin SSL dentro de la VPC privada
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project}-postgres16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = "${var.project}-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "twenty"
  username = "twenty"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.postgres.name
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}
