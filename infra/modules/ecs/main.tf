resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "twenty" {
  name              = "/ecs/${var.project}-twenty"
  retention_in_days = 7
}

locals {
  use_lab_role = var.lab_role_arn != null && var.lab_role_arn != ""
}

# Rol de ejecucion: descargar la imagen, escribir logs y leer el secreto
resource "aws_iam_role" "execution" {
  count = local.use_lab_role ? 0 : 1
  name  = "${var.project}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  count      = local.use_lab_role ? 0 : 1
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = local.use_lab_role ? 0 : 1
  role  = aws_iam_role.execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = var.secret_arn
    }]
  })
}

locals {
  execution_role_arn = local.use_lab_role ? var.lab_role_arn : aws_iam_role.execution[0].arn
  server_url         = "http://${var.alb_dns_name}"

  common_environment = [
    { name = "SERVER_URL", value = local.server_url },
    { name = "REDIS_URL", value = "redis://${var.redis_address}:6379" },
    { name = "STORAGE_TYPE", value = "local" },
  ]

  common_secrets = [
    for key in ["PG_DATABASE_URL", "ENCRYPTION_KEY", "APP_SECRET"] :
    { name = key, valueFrom = "${var.secret_arn}:${key}::" }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.twenty.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "twenty"
    }
  }
}

# Servidor web + API: ejecuta las migraciones de la base de datos al arrancar
resource "aws_ecs_task_definition" "server" {
  family                   = "${var.project}-twenty-server"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = local.execution_role_arn

  container_definitions = jsonencode([{
    name         = "twenty-server"
    image        = var.twenty_image
    essential    = true
    portMappings = [{ containerPort = 3000, protocol = "tcp" }]
    environment = concat(local.common_environment, [
      { name = "NODE_PORT", value = "3000" },
    ])
    secrets          = local.common_secrets
    logConfiguration = local.log_configuration
  }])
}

# Worker: procesa los trabajos en segundo plano encolados en Redis
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project}-twenty-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = local.execution_role_arn

  container_definitions = jsonencode([{
    name      = "twenty-worker"
    image     = var.twenty_image
    essential = true
    command   = ["yarn", "worker:prod"]
    environment = concat(local.common_environment, [
      { name = "DISABLE_DB_MIGRATIONS", value = "true" },
      { name = "DISABLE_CRON_JOBS_REGISTRATION", value = "true" },
    ])
    secrets          = local.common_secrets
    logConfiguration = local.log_configuration
  }])
}

resource "aws_ecs_service" "server" {
  name            = "${var.project}-twenty-server"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # El primer arranque corre migraciones y tarda varios minutos
  health_check_grace_period_seconds = 600

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "twenty-server"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "worker" {
  name            = "${var.project}-twenty-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  # El worker no corre migraciones: arranca despues del servidor
  depends_on = [aws_ecs_service.server]
}
