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

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
  default     = "download.lovelive-presents.com"
}

variable "rate_limit_requests" {
  description = "Number of requests allowed in 5-minute window before blocking"
  type        = number
  default     = 100
}

variable "block_duration_seconds" {
  description = "Duration to block IP after rate limit exceeded (in seconds)"
  type        = number
  default     = 3600 # 1 hour
}

variable "target_path" {
  description = "Target path to monitor for rate limiting"
  type        = string
  default     = "/website"
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID to associate with WAF"
  type        = string
  default     = ""
}
