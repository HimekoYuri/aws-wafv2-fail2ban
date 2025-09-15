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

variable "whitelist_ips" {
  description = "List of IP addresses to whitelist (never ban)"
  type        = list(string)
  default     = []
}

variable "blacklist_ips" {
  description = "List of IP addresses to blacklist (always ban)"
  type        = list(string)
  default     = []
}

variable "count_threshold" {
  description = "Threshold for count rule before triggering alerts"
  type        = number
  default     = 50
}

variable "enable_managed_rules" {
  description = "Enable AWS managed rules (disabled per requirement)"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel name for notifications"
  type        = string
  default     = "aws_system_notify"
}

variable "notification_email" {
  description = "Email address for SNS notifications"
  type        = string
  default     = ""
}

variable "teams_webhook_url" {
  description = "Microsoft Teams webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_advanced_rules" {
  description = "Enable advanced pattern matching and staged blocking rules"
  type        = bool
  default     = true
}

variable "enable_user_agent_filtering" {
  description = "Enable suspicious User-Agent filtering"
  type        = bool
  default     = true
}

variable "lambda_python_runtime" {
  description = "Python runtime version for Lambda functions"
  type        = string
  default     = "python3.13"

  validation {
    condition     = can(regex("^python3\\.(9|10|11|12|13)$", var.lambda_python_runtime))
    error_message = "Lambda Python runtime must be python3.9, python3.10, python3.11, python3.12, or python3.13."
  }
}
