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
