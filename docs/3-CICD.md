# 3. CI/CD de infraestructura
Workflows en `.github/workflows/`; autenticacion en la accion compuesta `.github/actions/aws-auth`
(OIDC si existe `AWS_ROLE_ARN`; si no, llaves de acceso y token de sesion).

Flujo: **PR -> infra-plan -> merge -> aprobacion en environment `production` -> infra-apply**.

| Workflow | Disparador | Que hace |
|---|---|---|
| `infra-plan` | `pull_request` con cambios en `infra/**` | `fmt -check -recursive`, `init`, `validate`, `plan -var-file=env/prod.tfvars`. Publica el plan como comentario del PR (lo actualiza si ya existe) |
| `infra-apply` | push a `main` en `infra/**`, o manual | Espera aprobacion en `production`, ejecuta `apply -auto-approve` y escribe los outputs en el resumen del job |
| `infra-destroy` | manual, input `confirm` | Falla si `confirm` no es exactamente `DESTROY`; luego espera aprobacion en `production` y ejecuta `destroy` |

- Los tres comparten el grupo de concurrencia `terraform-prod` (`cancel-in-progress: false`): nunca corren dos a la vez.
- El estado se inicializa con `-backend-config` (bucket y region desde variables del repo).
- Permisos: `id-token: write`, `contents: read` (y `pull-requests: write` en el plan).
- Configurar en GitHub el environment `production` con revisores requeridos y proteger la rama `main`.
