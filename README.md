# CRM con IaC, CI/CD y Observabilidad en AWS (Terraform)

**Materia:** Introducción a Modelos de Informática en la Nube — ITM  
**Integrantes:** Zara Ramírez Ortiz · Santiago Álzate Múnera · Mateo Bolívar Arroyave  
**Opción B:** una nube (AWS) con la aplicación usando dos bases de datos gestionadas.

## Arquitectura

| Componente | Servicio AWS | Rol |
|---|---|---|
| CRM [Twenty](https://twenty.com) (`app/Dockerfile`, base `twentycrm/twenty:v2.56.1`) | ECS Fargate (server + worker), Container Insights | Contenedores |
| Base de datos relacional | RDS PostgreSQL 16 | Empresas, contactos, oportunidades |
| Base de datos en memoria | ElastiCache Redis 7.1 | Caché, sesiones, cola de trabajos |
| Entrada pública | Application Load Balancer | HTTP :80 → server :3000 |
| Imágenes | ECR `crm-twenty` | Imagen de la aplicación |
| Secretos | Secrets Manager | URL de la BD, ENCRYPTION_KEY |
| Observabilidad | CloudWatch (dashboard, alarmas, metric filter) + SNS | Métricas y alertas por correo |
| Estado de Terraform | S3 versionado y cifrado (`use_lockfile`) | Estado remoto con bloqueo |

```
Internet → ALB (subred pública) → ECS Fargate: twenty-server ─┬→ RDS PostgreSQL     (subred privada)
                                   ECS Fargate: twenty-worker ─┴→ ElastiCache Redis (subred privada)
GitHub Actions → ECR (imagen) → ECS (force-new-deployment)      CloudWatch → SNS → correo
```

## Estructura

```
bootstrap/   Terraform con estado local, se aplica una vez: bucket S3, ECR, rol OIDC (opcional)
infra/       Terraform principal (backend S3)
  main.tf, variables.tf, outputs.tf, backend.tf, versions.tf
  env/prod.tfvars              valores del entorno (sin secretos)
  modules/{network,security,database,cache,secrets,ecs,alb,monitoring}
app/         Dockerfile de la imagen de la aplicación
.github/     workflows de infra y de la aplicación + acción compuesta aws-auth
docs/        documentación (1-Arquitectura.md … 7-Observabilidad.md) y evidencias
```

## Puesta en marcha

### 1. Bootstrap (una sola vez, desde tu equipo)
```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # AWS Academy: create_github_role = false
terraform init
terraform apply
terraform output
```
Con GitHub OIDC: `create_github_role = true`, `github_owner` y `github_repo`.

### 2. Configurar GitHub
- **Variables de repo:** `AWS_REGION`, `TF_STATE_BUCKET` (output `bucket`), `ECR_REPOSITORY` (`crm-twenty`), `ALERT_EMAIL`. Opcional: `LAB_ROLE_ARN` (AWS Academy, ARN de `LabRole`).
- **Secrets:** `AWS_ROLE_ARN` (output `role_arn`) para OIDC; si no existe se usan `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_SESSION_TOKEN` (en Learner Lab caducan: renovarlos en cada sesión).
- **Environment** `production` con revisores requeridos (aprobación manual de apply y destroy).

### 3. Publicar la imagen (app-deploy)
Ejecutar el workflow `app-deploy` (o push a `main` con cambios en `app/**`). Como el clúster aún no existe, solo hace build y push a ECR.

### 4. Infraestructura (PR → apply)
Abrir un PR con cambios en `infra/**`: `infra-plan` ejecuta fmt, init, validate y plan, y comenta el plan en el PR. Al hacer merge a `main`, `infra-apply` espera aprobación en `production`, aplica y publica los outputs (`crm_url`, `dashboard_url`) en el resumen del job.

El primer arranque del server corre las migraciones (varios minutos):
```bash
aws logs tail /ecs/crm-twenty --follow
```
Confirmar la suscripción de correo que SNS envía a `ALERT_EMAIL`.

### Ejecución local de infra (opcional)
```bash
cd infra
terraform init -backend-config="bucket=<TF_STATE_BUCKET>" -backend-config="key=crm/prod/terraform.tfstate" -backend-config="region=us-east-1"
terraform plan -var-file=env/prod.tfvars -var alert_email=tu@correo.com
```

## Flujo de ramas
- `main`: rama protegida, refleja producción. Solo recibe merges por PR.
- `feature/*`: cambios en `infra/**` o `app/**`. El PR dispara `infra-plan` (si toca infra); el merge dispara `infra-apply` y/o `app-deploy`.

## Rollback
Cada despliegue publica la imagen con el tag del commit (`${{ github.sha }}`) además de `latest`. Para volver atrás:
1. Identificar el tag anterior en ECR (o el SHA del último commit bueno).
2. Reasignar `latest` a ese tag:
   ```bash
   MANIFEST=$(aws ecr batch-get-image --repository-name crm-twenty --image-ids imageTag=<SHA_ANTERIOR> --query 'images[0].imageManifest' --output text)
   aws ecr put-image --repository-name crm-twenty --image-tag latest --image-manifest "$MANIFEST"
   ```
3. Re-desplegar: `aws ecs update-service --cluster crm-cluster --service crm-twenty-server --force-new-deployment` (y `crm-twenty-worker`), o reejecutar `app-deploy` sobre el commit anterior (`workflow_dispatch` en esa referencia).

Alternativa: fijar `app_image` en `infra/env/prod.tfvars` a `<cuenta>.dkr.ecr.<region>.amazonaws.com/crm-twenty:<SHA_ANTERIOR>` y aplicar por PR. Los cambios de infraestructura se revierten con `git revert` y un nuevo PR.

## Destruir (¡hacerlo siempre al terminar! ≈ US$2–3/día)
Workflow `infra-destroy` (input `confirm` = `DESTROY`, con aprobación). Después, `terraform destroy` en `bootstrap/` si se quiere borrar bucket y ECR (vaciar el bucket versionado antes).

## Notas de diseño (sin cambios respecto a la versión anterior)
`rds.force_ssl=0`, `maxmemory-policy=noeviction`, `health_check_grace_period_seconds=600` y worker sin migraciones (`DISABLE_DB_MIGRATIONS=true`) se conservan igual.
