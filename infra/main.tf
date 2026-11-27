module "network" {
  source  = "./modules/network"
  project = var.project
}

module "security" {
  source  = "./modules/security"
  project = var.project
  vpc_id  = module.network.vpc_id
}

module "database" {
  source             = "./modules/database"
  project            = var.project
  private_subnet_ids = module.network.private_subnet_ids
  security_group_id  = module.security.rds_sg_id
  db_instance_class  = var.db_instance_class
}

module "cache" {
  source             = "./modules/cache"
  project            = var.project
  private_subnet_ids = module.network.private_subnet_ids
  security_group_id  = module.security.redis_sg_id
  redis_node_type    = var.redis_node_type
}

module "secrets" {
  source      = "./modules/secrets"
  project     = var.project
  db_address  = module.database.address
  db_name     = module.database.db_name
  db_username = module.database.username
  db_password = module.database.password
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.alb_sg_id
}

module "ecs" {
  source            = "./modules/ecs"
  project           = var.project
  region            = var.region
  twenty_image      = var.twenty_image
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.ecs_sg_id
  target_group_arn  = module.alb.target_group_arn
  alb_dns_name      = module.alb.dns_name
  redis_address     = module.cache.address
  secret_arn        = module.secrets.secret_arn
}

module "monitoring" {
  source                  = "./modules/monitoring"
  project                 = var.project
  region                  = var.region
  alert_email             = var.alert_email
  cluster_name            = module.ecs.cluster_name
  server_service_name     = module.ecs.server_service_name
  worker_service_name     = module.ecs.worker_service_name
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  db_identifier           = module.database.identifier
  redis_cluster_id        = module.cache.cluster_id
  log_group_name          = module.ecs.log_group_name
  log_error_threshold     = var.log_error_threshold
}
