variable "domain_name" {
  description = "Domain name for the website"
  type        = string
  default     = "download.lovelive-presents.com"
}

variable "rate_limit_requests" {
  description = "Number of requests allowed in 5-minute window before blocking"
  type        = number
  default     = 100

  validation {
    condition     = var.rate_limit_requests >= 100 && var.rate_limit_requests <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000 (WAFv2 constraint)."
  }
}

variable "block_duration_seconds" {
  description = "Duration to block IP after rate limit exceeded (in seconds)"
  type        = number
  default     = 3600
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
  description = "List of IP addresses to whitelist (CIDR notation, never ban)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.whitelist_ips : can(cidrhost(ip, 0))])
    error_message = "All whitelist IPs must be valid CIDR notation (e.g., 192.168.1.0/24)."
  }
}

variable "blacklist_ips" {
  description = "List of IP addresses to blacklist (CIDR notation, always ban)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.blacklist_ips : can(cidrhost(ip, 0))])
    error_message = "All blacklist IPs must be valid CIDR notation (e.g., 203.0.113.0/24)."
  }
}

variable "count_threshold" {
  description = "Threshold for count rule before triggering alerts"
  type        = number
  default     = 50

  validation {
    condition     = var.count_threshold >= 100
    error_message = "Count threshold must be at least 100 (WAFv2 rate-based minimum)."
  }
}

variable "enable_managed_rules" {
  description = "Enable AWS managed rules (AWSManagedRulesCommonRuleSet etc.)"
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
    condition     = can(regex("^python3\\.(11|12|13)$", var.lambda_python_runtime))
    error_message = "Lambda Python runtime must be python3.11, python3.12, or python3.13."
  }
}

variable "enable_ai_attack_protection" {
  description = "Enable protection against AI-driven automated attacks (2026 threat landscape)"
  type        = bool
  default     = true
}

variable "enable_api_abuse_protection" {
  description = "Enable API abuse and SSRF protection patterns"
  type        = bool
  default     = true
}

variable "ip_ttl_hours" {
  description = "Hours before auto-removing IPs from offender lists (0 = never expire)"
  type        = number
  default     = 24
}
