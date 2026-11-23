# CRM con Infraestructura como Código en AWS (Terraform)

**Materia:** Introducción a Modelos de Informática en la Nube — ITM, entrega 13 nov 2026  
**Integrantes:** Zara Ramírez Ortiz · Santiago Álzate Múnera · Mateo Bolívar Arroyave
**Opción B:** una nube (AWS) con la aplicación usando dos bases de datos gestionadas.

| Componente | Servicio AWS | Rol |
|---|---|---|
| CRM [Twenty](https://twenty.com) (`twentycrm/twenty:v2.56.1`) | ECS Fargate (server + worker) | Contenedores |
| Base de datos relacional | RDS PostgreSQL 16 | Empresas, contactos, oportunidades |
| Base de datos en memoria | ElastiCache Redis 7.1 | Caché, sesiones, cola de trabajos |
| Entrada pública | Application Load Balancer | HTTP :80 → server :3000 |
| Secretos | Secrets Manager | URL de la BD, ENCRYPTION_KEY |
| Logs | CloudWatch Logs | `/ecs/crm-twenty` |

```
Internet → ALB (subred pública) → ECS Fargate: twenty-server ─┬→ RDS PostgreSQL   (subred privada)
                                   ECS Fargate: twenty-worker ─┴→ ElastiCache Redis (subred privada)
```

## Desplegar
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # en AWS Academy: descomentar lab_role_arn
terraform init
terraform plan
terraform apply          # ~10-15 min (RDS + ElastiCache son lo más lento)
terraform output crm_url
```
El primer arranque del server corre las migraciones (varios minutos). Seguir el progreso con:
```bash
aws logs tail /ecs/crm-twenty --follow
```
Cuando el target group esté *healthy*, abrir `crm_url`, registrarse y crear el workspace.

## Destruir (¡hacerlo siempre al terminar! ≈ US$2–3/día)
```bash
terraform destroy
```

## Archivos
- `terraform/network.tf` VPC, 2 subredes públicas + 2 privadas en 2 AZ
- `terraform/security.tf` security groups (ALB → ECS → RDS/Redis)
- `terraform/rds.tf` PostgreSQL gestionado · `terraform/redis.tf` Redis gestionado
- `terraform/secrets.tf` contraseñas generadas + Secrets Manager
- `terraform/ecs.tf` cluster, task definitions y servicios · `terraform/alb.tf` balanceador
