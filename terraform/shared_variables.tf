variable "aws_region" {
  description = "AWS region (us-east-1 required for CloudFront WAF)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "CloudFront WAF requires us-east-1 region."
  }
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

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}
