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

output "whitelist_ip_set_arn" {
  description = "The ARN of the whitelist IP set"
  value       = aws_wafv2_ip_set.whitelist.arn
}

output "blacklist_ip_set_arn" {
  description = "The ARN of the blacklist IP set"
  value       = aws_wafv2_ip_set.blacklist.arn
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
    count_threshold   = var.count_threshold
    requests_per_5min = var.rate_limit_requests
    block_duration    = var.block_duration_seconds
    target_path       = var.target_path
  }
}

output "alarm_names" {
  description = "CloudWatch alarm names for monitoring"
  value = {
    count_threshold = aws_cloudwatch_metric_alarm.count_threshold_alarm.alarm_name
    block_added     = aws_cloudwatch_metric_alarm.block_added_alarm.alarm_name
    block_cleared   = aws_cloudwatch_metric_alarm.block_cleared_alarm.alarm_name
  }
}
