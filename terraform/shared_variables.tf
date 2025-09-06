variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile name"
  type        = string
  default     = "YukiSunaoka"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
