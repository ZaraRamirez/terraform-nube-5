# 6. Observabilidad
Modulo `infra/modules/monitoring`. Container Insights esta activo en el cluster ECS.

- **Dashboard** `crm-observabilidad` (URL en el output `dashboard_url`): CPU y memoria de ECS, solicitudes, 5XX, latencia y
  hosts sanos del ALB, CPU/conexiones/almacenamiento de RDS, CPU/memoria/conexiones de Redis.
- **SNS:** topico `crm-alertas` con suscripcion por correo a `alert_email`. Hay que aceptar el correo de confirmacion.
- **Alarmas:** hosts no saludables del ALB, 5XX del ALB, server sin tareas, CPU de RDS, poco almacenamiento en RDS,
  memoria de Redis y errores en logs.
- **Metric filter:** busca `ERROR` en el log group `/ecs/crm-twenty` y publica `CRM/Logs ErrorCount`.
  La alarma salta con mas de `log_error_threshold` (5) lineas en 5 minutos.
- Logs: `aws logs tail /ecs/crm-twenty --follow`.

## Probar una alarma
1. Apagar el servicio server:
   `aws ecs update-service --cluster crm-cluster --service crm-twenty-server --desired-count 0`
2. En 2 a 5 minutos la alarma `crm-ecs-server-sin-tareas` pasa a `ALARM` y llega el correo.
3. Restaurar: mismo comando con `--desired-count 1`. La alarma vuelve a `OK`.
4. Terraform volvera a fijar `desired_count = 1` en el siguiente apply.
