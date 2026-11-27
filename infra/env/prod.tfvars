# Valores del entorno de produccion (sin secretos).
# alert_email llega por TF_VAR_alert_email (variable de repo ALERT_EMAIL).
region            = "us-east-1"
project           = "crm"
twenty_image      = "twentycrm/twenty:v2.56.1"
db_instance_class = "db.t3.micro"
redis_node_type   = "cache.t3.micro"
