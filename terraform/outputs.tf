# Outputs removed to minimize complexity
# Web ACL information can be found in AWS Console if needed

output "teams_lambda_function_name" {
  description = "Name of the Teams notification Lambda function"
  value       = var.teams_webhook_url != "" ? aws_lambda_function.teams_notifier[0].function_name : null
  sensitive   = true
}
