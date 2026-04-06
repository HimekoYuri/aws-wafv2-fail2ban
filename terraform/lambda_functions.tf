# =============================================================================
# IP Manager Lambda関数 (TTL対応)
# =============================================================================

# IAMロール
resource "aws_iam_role" "ip_manager_lambda_role" {
  name = "fail2ban-ip-manager-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAMポリシー
resource "aws_iam_role_policy" "ip_manager_lambda_policy" {
  name = "fail2ban-ip-manager-lambda-policy"
  role = aws_iam_role.ip_manager_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ]
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid    = "WAFv2IPSets"
        Effect = "Allow"
        Action = [
          "wafv2:GetIPSet",
          "wafv2:UpdateIPSet"
        ]
        Resource = [
          aws_wafv2_ip_set.repeat_offenders.arn,
          aws_wafv2_ip_set.heavy_offenders.arn
        ]
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda ZIP
data "archive_file" "ip_manager_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/ip_manager.py"
  output_path = "${path.module}/lambda/ip_manager.zip"
}

# Lambda関数
resource "aws_lambda_function" "ip_manager" {
  filename         = data.archive_file.ip_manager_lambda_zip.output_path
  function_name    = "fail2ban-ip-manager"
  role             = aws_iam_role.ip_manager_lambda_role.arn
  handler          = "ip_manager.handler"
  runtime          = var.lambda_python_runtime
  timeout          = 120
  memory_size      = 256
  source_code_hash = data.archive_file.ip_manager_lambda_zip.output_base64sha256

  environment {
    variables = {
      REPEAT_OFFENDERS_IP_SET_ID   = aws_wafv2_ip_set.repeat_offenders.id
      HEAVY_OFFENDERS_IP_SET_ID    = aws_wafv2_ip_set.heavy_offenders.id
      REPEAT_OFFENDERS_IP_SET_NAME = aws_wafv2_ip_set.repeat_offenders.name
      HEAVY_OFFENDERS_IP_SET_NAME  = aws_wafv2_ip_set.heavy_offenders.name
      IP_TTL_HOURS                 = tostring(var.ip_ttl_hours)
    }
  }

  tags = {
    Name = "fail2ban-ip-manager"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "ip_manager_logs" {
  name              = "/aws/lambda/fail2ban-ip-manager"
  retention_in_days = 14

  tags = {
    Name = "fail2ban-ip-manager-logs"
  }
}

# SNS → Lambda 権限
resource "aws_lambda_permission" "allow_sns_ip_manager" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ip_manager.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.waf_notifications.arn
}

# SNSサブスクリプション
resource "aws_sns_topic_subscription" "ip_manager_subscription" {
  topic_arn = aws_sns_topic.waf_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ip_manager.arn
}
