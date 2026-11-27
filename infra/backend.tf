# Estado remoto en S3 con bloqueo nativo (use_lockfile, Terraform >= 1.10).
# bucket, key y region se pasan al inicializar:
#   terraform init \
#     -backend-config="bucket=<TF_STATE_BUCKET>" \
#     -backend-config="key=crm/prod/terraform.tfstate" \
#     -backend-config="region=us-east-1"
terraform {
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
