locals {
  dashboard_name = "crm-observabilidad"

  ecs_server_dims = ["ClusterName", var.cluster_name, "ServiceName", var.server_service_name]
  ecs_worker_dims = ["ClusterName", var.cluster_name, "ServiceName", var.worker_service_name]
  alb_dims        = ["LoadBalancer", var.alb_arn_suffix]
  alb_tg_dims     = ["TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix]

  # Layout: 3 widgets por fila (8 columnas cada uno)
  widgets = [
    for i, w in [
      { title = "ECS CPU (%)", metrics = [
        ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.server_service_name, { label = "server" }],
        ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.worker_service_name, { label = "worker" }],
      ], stat = "Average" },
      { title = "ECS Memoria (%)", metrics = [
        ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.server_service_name, { label = "server" }],
        ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.worker_service_name, { label = "worker" }],
      ], stat = "Average" },
      { title = "ALB RequestCount", metrics = [
        concat(["AWS/ApplicationELB", "RequestCount"], local.alb_dims),
      ], stat = "Sum" },
      { title = "ALB HTTPCode_Target_5XX_Count", metrics = [
        concat(["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"], local.alb_dims),
      ], stat = "Sum" },
      { title = "ALB TargetResponseTime (s)", metrics = [
        concat(["AWS/ApplicationELB", "TargetResponseTime"], local.alb_dims),
      ], stat = "Average" },
      { title = "ALB HealthyHostCount", metrics = [
        concat(["AWS/ApplicationELB", "HealthyHostCount"], local.alb_tg_dims),
      ], stat = "Minimum" },
      { title = "RDS CPU (%)", metrics = [
        ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_identifier],
      ], stat = "Average" },
      { title = "RDS DatabaseConnections", metrics = [
        ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier],
      ], stat = "Average" },
      { title = "RDS FreeStorageSpace (bytes)", metrics = [
        ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_identifier],
      ], stat = "Minimum" },
      { title = "Redis CPUUtilization (%)", metrics = [
        ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.redis_cluster_id],
      ], stat = "Average" },
      { title = "Redis DatabaseMemoryUsagePercentage", metrics = [
        ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", var.redis_cluster_id],
      ], stat = "Average" },
      { title = "Redis CurrConnections", metrics = [
        ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", var.redis_cluster_id],
      ], stat = "Average" },
      ] : {
      type   = "metric"
      x      = (i % 3) * 8
      y      = floor(i / 3) * 6
      width  = 8
      height = 6
      properties = {
        title   = w.title
        region  = var.region
        view    = "timeSeries"
        stat    = w.stat
        period  = 300
        metrics = w.metrics
      }
    }
  ]
}

# ---------- Notificaciones ----------
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alertas"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- Dashboard ----------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.dashboard_name
  dashboard_body = jsonencode({ widgets = local.widgets })
}

# ---------- Alarmas ----------
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "${var.project}-alb-unhealthy-hosts"
  alarm_description   = "El ALB tiene targets no saludables"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = { TargetGroup = var.target_group_arn_suffix, LoadBalancer = var.alb_arn_suffix }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-alb-5xx"
  alarm_description   = "Mas de 5 errores 5XX del target en 5 minutos"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# Requiere Container Insights habilitado en el cluster
resource "aws_cloudwatch_metric_alarm" "ecs_server_running" {
  alarm_name          = "${var.project}-ecs-server-sin-tareas"
  alarm_description   = "El servicio server tiene menos de 1 tarea en ejecucion"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  dimensions          = { ClusterName = var.cluster_name, ServiceName = var.server_service_name }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project}-rds-cpu-alta"
  alarm_description   = "CPU de RDS por encima de 80%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = var.db_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project}-rds-poco-almacenamiento"
  alarm_description   = "Menos de 2 GB libres en RDS"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.db_identifier }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2 * 1024 * 1024 * 1024
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.project}-redis-memoria-alta"
  alarm_description   = "Memoria de Redis por encima de 80%"
  namespace           = "AWS/ElastiCache"
  metric_name         = "DatabaseMemoryUsagePercentage"
  dimensions          = { CacheClusterId = var.redis_cluster_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ---------- Errores en logs ----------
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.project}-errores-en-logs"
  log_group_name = var.log_group_name
  pattern        = "ERROR"

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "CRM/Logs"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_errors" {
  alarm_name          = "${var.project}-errores-en-logs"
  alarm_description   = "Mas de ${var.log_error_threshold} lineas ERROR en 5 minutos en ${var.log_group_name}"
  namespace           = "CRM/Logs"
  metric_name         = aws_cloudwatch_log_metric_filter.errors.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.log_error_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
