output "web_acl_id" {
  description = "The ID of the WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.fail2ban_acl.id
}

output "web_acl_arn" {
  description = "The ARN of the WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.fail2ban_acl.arn
}

output "web_acl_name" {
  description = "The name of the WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.fail2ban_acl.name
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_log_group.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_log_group.arn
}

output "rate_limit_configuration" {
  description = "Rate limiting configuration details"
  value = {
    requests_per_5min = var.rate_limit_requests
    block_duration    = var.block_duration_seconds
    target_path       = var.target_path
  }
}
