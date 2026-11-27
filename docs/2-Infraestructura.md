# 2. Infraestructura
Dos configuraciones de Terraform (>= 1.10):

## bootstrap/ (una sola vez, estado local)
- Bucket S3 del estado `<project>-tfstate-<account_id>`: versionado, cifrado AES256, acceso publico bloqueado.
- Proveedor OIDC de GitHub y rol IAM para Actions, solo si `create_github_role = true`.
  En AWS Academy Learner Lab se deja en `false` (no permite crear roles).
- Salidas: `bucket` (variable `TF_STATE_BUCKET`) y `role_arn` (secreto `AWS_ROLE_ARN`).
- Valores locales en `bootstrap/terraform.tfvars` (ignorado por git); plantilla en `terraform.tfvars.example`.

## infra/ (backend S3, `use_lockfile = true`)
| Modulo | Contenido |
|---|---|
| `network` | VPC, subredes, internet gateway, rutas |
| `security` | Security groups |
| `database` | RDS PostgreSQL y parameter group |
| `cache` | ElastiCache Redis y parameter group |
| `secrets` | Secreto con credenciales y claves |
| `alb` | Load balancer, target group, listener |
| `ecs` | Cluster, log group, IAM, task definitions, servicios |
| `monitoring` | SNS, dashboard, alarmas, metric filter |

- Valores del entorno: `infra/env/prod.tfvars` (region, prefijo, tamanos, `twenty_image`). Sin secretos.
- `alert_email` llega por `TF_VAR_alert_email` (variable `ALERT_EMAIL`); `lab_role_arn` por `TF_VAR_lab_role_arn` (opcional).
