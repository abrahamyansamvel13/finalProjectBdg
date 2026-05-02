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
  description = "AWS Key Pair name"
  type        = string
  default     = "gaming-stats-new"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "gaming_admin"
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "gaming_stats"
}

# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "gaming-stats-vpc"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# SUBNETS
# ─────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "gaming-stats-public-subnet"
    Project = "gaming-stats-api"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name    = "gaming-stats-private-subnet-1"
    Project = "gaming-stats-api"
  }
}

# Second private subnet — required for RDS DB Subnet Group (must span 2 AZs)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1c"

  tags = {
    Name    = "gaming-stats-private-subnet-2"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# INTERNET GATEWAY
# ─────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "gaming-stats-igw"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# ROUTE TABLES
# ─────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "gaming-stats-public-rt"
    Project = "gaming-stats-api"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "gaming-stats-private-rt"
    Project = "gaming-stats-api"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# ─────────────────────────────────────────
# SECURITY GROUPS
# ─────────────────────────────────────────

# EC2 Security Group
resource "aws_security_group" "app_sg" {
  name        = "gaming-stats-app-sg"
  description = "Allow HTTP and SSH inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "gaming-stats-app-sg"
    Project = "gaming-stats-api"
  }
}

# RDS Security Group — only accepts traffic from app_sg
resource "aws_security_group" "db_sg" {
  name        = "gaming-stats-db-sg"
  description = "Allow PostgreSQL only from app_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "gaming-stats-db-sg"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# RDS DB SUBNET GROUP
# ─────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "gaming-stats-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name    = "gaming-stats-db-subnet-group"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# RDS — PostgreSQL Free Tier
# ─────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "gaming-stats-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name    = "gaming-stats-rds"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# EC2 — Application Server
# ─────────────────────────────────────────
resource "aws_instance" "app" {
  ami                    = "ami-0989fb15ce71ba39e"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y git docker.io docker-compose

    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    cd /home/ubuntu
    git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
    cd finalProjectBdg

    echo "DATABASE_URL=postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}" > .env

    docker-compose up -d
  EOF

  tags = {
    Name    = "gaming-stats-server"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# OUTPUTS
# ─────────────────────────────────────────
output "vpc_id" {
  value = aws_vpc.main.id
}

output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_instance.app.public_ip}"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_url" {
  description = "Full DATABASE_URL for the app"
  value       = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive   = true
}
