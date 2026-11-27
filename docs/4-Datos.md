# 4. Datos
Twenty usa dos almacenes con funciones distintas, por eso se despliegan ambos.

## RDS PostgreSQL 16 (`db.t3.micro`)
- Base relacional y fuente de verdad: empresas, personas, oportunidades, workspaces y metadatos.
- Necesita persistencia, transacciones y respaldos; no puede vivir en el contenedor, que es efimero.
- Subredes privadas, sin acceso publico. Solo el security group de ECS entra por 5432.
- Contrasena generada por Terraform (`random_password`) y guardada en Secrets Manager.

## ElastiCache Redis 7.1 (`cache.t3.micro`)
- Cache, sesiones y cola de trabajos (BullMQ) que consume el worker.
- Es memoria rapida; PostgreSQL no sirve bien para colas ni sesiones con baja latencia.
- Politica `maxmemory-policy = noeviction`: Redis rechaza escrituras antes que borrar trabajos encolados.
- Subredes privadas; solo el security group de ECS entra por 6379.

## Almacenamiento de archivos
`STORAGE_TYPE = local`: los adjuntos se guardan en el disco de la tarea y se pierden al reemplazarla.
Para produccion real se cambiaria a S3.
