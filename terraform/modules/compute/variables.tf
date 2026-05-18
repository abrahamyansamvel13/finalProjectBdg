variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB and ASG"
  type        = list(string)
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "key_name" {
  description = "AWS Key Pair name for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "ASG minimum instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "ASG maximum instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "ASG desired instances"
  type        = number
  default     = 2
}

variable "db_endpoint" {
  description = "RDS endpoint passed from root"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

# IAM Instance Profile — passed from root (created in secrets.tf)
variable "iam_instance_profile" {
  description = "IAM instance profile name for EC2 to access Secrets Manager"
  type        = string
}

# Secret ARN — passed from root
variable "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  type        = string
}
