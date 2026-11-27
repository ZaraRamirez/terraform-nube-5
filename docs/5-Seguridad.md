# 5. Seguridad
- **OIDC:** GitHub Actions asume un rol IAM con tokens temporales; no se guardan llaves de larga duracion.
  La confianza se limita a `repo:<OWNER>/<REPO>:*`. Sin OIDC (AWS Academy) se usan llaves temporales como secretos del repo.
- **Subredes privadas:** RDS y Redis no tienen ruta a internet ni IP publica.
- **Security groups encadenados:** Internet -> ALB (80) -> ECS (3000) -> RDS (5432) y Redis (6379).
  Cada regla de entrada referencia el security group anterior, no rangos de IP.
- **Secrets Manager:** guarda `PG_DATABASE_URL`, `ENCRYPTION_KEY` y `APP_SECRET`. ECS los inyecta al contenedor
  con el rol de ejecucion, que solo puede leer ese secreto.
- **Estado de Terraform:** bucket S3 privado, versionado y cifrado. El estado contiene las contrasenas generadas.
- **Repositorio:** `.gitignore` excluye `*.tfstate`, `*.tfplan`, `*.log`, `bootstrap/terraform.tfvars` y `*.auto.tfvars`.
  `infra/env/prod.tfvars` no contiene secretos.
- **Aprobacion humana:** `apply` y `destroy` requieren aprobacion en el environment `production`.
- **Limitaciones:** el ALB usa HTTP (sin dominio ni certificado) y las tareas ECS tienen IP publica para evitar el NAT.
