variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "environment" { type = string }
variable "key_name" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "db_endpoint" { type = string }
variable "db_name" { type = string }
# Дефолтные значения из задания
variable "instance_type" { default = "t3.micro" }
variable "min_size" { default = 2 }
variable "max_size" { default = 4 }
variable "desired_capacity" { default = 2 }
