# 7. Operacion
## Puesta en marcha desde cero
1. `cd bootstrap; cp terraform.tfvars.example terraform.tfvars; terraform init; terraform apply`.
2. En GitHub: variables `AWS_REGION`, `TF_STATE_BUCKET`, `ALERT_EMAIL`; secreto `AWS_ROLE_ARN`
   (o `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`); environment `production` con revisores.
3. Abrir un PR con cambios en `infra/**` y revisar el plan comentado.
4. Hacer merge y aprobar `infra-apply` en `production`. El primer arranque corre migraciones (varios minutos).
5. Abrir `crm_url` (resumen del job) y confirmar la suscripcion de correo de SNS.

## Rollback
Revertir el commit con `git revert <sha>`, abrir PR, revisar el plan y aprobar el apply.
Terraform restaura el estado anterior de la infraestructura.

## Cambiar la version del CRM
Editar `twenty_image` en `infra/env/prod.tfvars` (por ejemplo `twentycrm/twenty:v2.57.0`) en un PR.
El plan muestra el cambio de task definition; tras el merge y la aprobacion, ECS reemplaza las tareas.

## Destruir
Workflow `infra-destroy` con `confirm = DESTROY`. Despues, `terraform destroy` en `bootstrap/`
(vaciar antes el bucket versionado).

## Costos aproximados (us-east-1, 24 h/dia)
| Recurso | USD/dia |
|---|---|
| ECS Fargate (1 vCPU/2 GB + 0,5 vCPU/1 GB) | 1,8 |
| ALB | 0,6 |
| RDS `db.t3.micro` | 0,4 |
| ElastiCache `cache.t3.micro` | 0,4 |
| IPv4 publicas y logs | 0,5 |
| **Total** | **3 (unos 90 al mes)** |
