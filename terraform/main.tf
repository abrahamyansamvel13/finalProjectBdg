terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "gaming-stats-tfstate-4ada4094"
    key            = "terraform/state"
    region         = "eu-north-1"
    dynamodb_table = "gaming-stats-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

# ─────────────────────────────────────────
# VARIABLES
# ─────────────────────────────────────────
variable "key_name" {
  type    = string
  default = "gaming-stats-new"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type    = string
  default = "gaming_admin"
}

variable "db_name" {
  type    = string
  default = "gaming_stats"
}

# ─────────────────────────────────────────
# MODULES
# ─────────────────────────────────────────
module "networking" {
  source               = "./modules/networking"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.5.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24", "10.0.3.0/24"]
  environment          = "gaming-stats"
  availability_zones   = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

module "compute" {
  source               = "./modules/compute"
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  environment          = "gaming-stats"
  key_name             = var.key_name
  db_endpoint          = aws_db_instance.main.endpoint
  db_name              = var.db_name

  # Secrets Manager integration
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  secret_arn           = aws_secretsmanager_secret.db_credentials.arn
}

# ─────────────────────────────────────────
# RDS (stays in root per task requirements)
# ─────────────────────────────────────────
resource "aws_security_group" "db_sg" {
  name        = "gaming-stats-db-sg"
  description = "Allow PostgreSQL only from app_sg"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.compute.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "gaming-stats-db-sg", Project = "gaming-stats-api" }
}

resource "aws_db_subnet_group" "main" {
  name       = "gaming-stats-db-subnet-group"
  subnet_ids = module.networking.private_subnet_ids
  tags       = { Name = "gaming-stats-db-subnet-group", Project = "gaming-stats-api" }
}

resource "aws_db_instance" "main" {
  identifier             = "gaming-stats-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags                   = { Name = "gaming-stats-rds", Project = "gaming-stats-api" }
}

# ─────────────────────────────────────────
# OUTPUTS
# ─────────────────────────────────────────
output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "app_url" {
  value = "http://${module.compute.alb_dns_name}"
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "secret_arn" {
  description = "ARN of the DB credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
