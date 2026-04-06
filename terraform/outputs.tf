# =============================================================================
# Outputs
# =============================================================================

output "advanced_waf_acl_id" {
  description = "ID of the advanced WAF ACL"
  value       = aws_wafv2_web_acl.fail2ban_advanced_acl.id
}

output "advanced_waf_acl_arn" {
  description = "ARN of the advanced WAF ACL"
  value       = aws_wafv2_web_acl.fail2ban_advanced_acl.arn
}

output "repeat_offenders_ip_set_id" {
  description = "ID of the repeat offenders IP set"
  value       = aws_wafv2_ip_set.repeat_offenders.id
}

output "heavy_offenders_ip_set_id" {
  description = "ID of the heavy offenders IP set"
  value       = aws_wafv2_ip_set.heavy_offenders.id
}

output "ip_manager_lambda_function_name" {
  description = "Name of the IP manager Lambda function"
  value       = aws_lambda_function.ip_manager.function_name
}

output "ip_manager_lambda_arn" {
  description = "ARN of the IP manager Lambda function"
  value       = aws_lambda_function.ip_manager.arn
}

output "sns_topic_arn" {
  description = "ARN of the WAF notifications SNS topic"
  value       = aws_sns_topic.waf_notifications.arn
}
