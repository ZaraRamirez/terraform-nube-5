# 1. Arquitectura
CRM [Twenty](https://twenty.com) sobre AWS (`us-east-1`), desplegado con Terraform y GitHub Actions.

```
Internet -> ALB (subred publica) -> ECS Fargate: twenty-server -+-> RDS PostgreSQL     (subred privada)
                                    ECS Fargate: twenty-worker -+-> ElastiCache Redis (subred privada)
GitHub Actions (OIDC) -> Terraform -> AWS          CloudWatch -> SNS -> correo
```

- **network:** VPC 10.0.0.0/16, 2 subredes publicas (ALB y tareas ECS, sin NAT) y 2 privadas (datos).
- **security:** security groups ALB, ECS, RDS y Redis, encadenados.
- **database:** RDS PostgreSQL 16 (`db.t3.micro`).
- **cache:** ElastiCache Redis 7.1 (`cache.t3.micro`).
- **secrets:** secreto en Secrets Manager con la URL de la BD, `ENCRYPTION_KEY` y `APP_SECRET`.
- **alb:** balanceador HTTP :80, health check en `/healthz`.
- **ecs:** cluster Fargate con Container Insights; servicios `crm-twenty-server` (1 vCPU, 2 GB) y `crm-twenty-worker` (0,5 vCPU, 1 GB).
- **monitoring:** dashboard, alarmas, topico SNS y metric filter de logs.
- **Imagen:** `twentycrm/twenty` desde Docker Hub, version fijada en la variable `twenty_image`.
- **Estado:** bucket S3 versionado y cifrado creado por `bootstrap/`.
