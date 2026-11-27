output "bucket" {
  description = "Bucket S3 del estado de Terraform (variable de repo TF_STATE_BUCKET)"
  value       = aws_s3_bucket.state.bucket
}

output "role_arn" {
  description = "ARN del rol de GitHub Actions (secret AWS_ROLE_ARN). null si create_github_role = false"
  value       = try(aws_iam_role.github[0].arn, null)
}
