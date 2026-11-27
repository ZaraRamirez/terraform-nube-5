output "dns_name" {
  value = aws_lb.main.dns_name
}

output "arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "target_group_arn" {
  description = "ARN del target group; se evalua despues de crear el listener"
  value       = aws_lb_target_group.server.arn
  depends_on  = [aws_lb_listener.http]
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.server.arn_suffix
}
