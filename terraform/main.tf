terraform {
  backend "s3" {
    bucket         = "gaming-stats-tfstate-4ada4094"
    key            = "terraform/state"
    region         = "eu-north-1"
    dynamodb_table = "gaming-stats-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
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
# Subnets
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

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name    = "gaming-stats-private-subnet"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# Internet Gateway
# ─────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "gaming-stats-igw"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# Route Tables
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

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ─────────────────────────────────────────
# Security Group
# ─────────────────────────────────────────
resource "aws_security_group" "app" {
  name        = "gaming-stats-sg"
  description = "Allow HTTP, HTTPS and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Alternate port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FastAPI direct"
    from_port   = 8000
    to_port     = 8000
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
    Name    = "gaming-stats-sg"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# EC2 Key Pair name (set yours here)
# ─────────────────────────────────────────
variable "key_name" {
  description = "Name of your AWS Key Pair for SSH access"
  type        = string
  default     = "gaming-stats-new"
}

# ─────────────────────────────────────────
# EC2 Instance
# ─────────────────────────────────────────
resource "aws_instance" "app" {
  ami                    = "ami-0989fb15ce71ba39e" # Amazon Linux 2 eu-north-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    cd /home/ubuntu
    git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
    cd finalProjectBdg
    docker-compose up -d --build
  USERDATA

  tags = {
    Name    = "gaming-stats-server"
    Project = "gaming-stats-api"
  }
}

# ─────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "ec2_public_ip" {
  description = "Public IP — open this in your browser"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Gaming Stats API URL"
  value       = "http://${aws_instance.app.public_ip}"
}

