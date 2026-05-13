resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name    = "gaming-stats-vpc"
    Project = "gaming-stats-api"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name    = "gaming-stats-public-subnet-${count.index + 1}"
    Project = "gaming-stats-api"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  # Измени индекс здесь с [count.index] на [count.index + 1]
  availability_zone = var.availability_zones[count.index + 1] 

  tags = {
    # Исправляем имена, чтобы они в точности совпали со старыми
    Name    = "gaming-stats-private-subnet-${count.index + 1}"
    Project = "gaming-stats-api"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "gaming-stats-igw"
    Project = "gaming-stats-api"
  }
}

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

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Для упрощения используем одну RT для приватных подсетей (без NAT по заданию)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "gaming-stats-private-rt"
    Project = "gaming-stats-api"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
