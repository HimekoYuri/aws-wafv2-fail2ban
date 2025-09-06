# SNS Topic for WAF notifications
resource "aws_sns_topic" "waf_notifications" {
  name = "waf-fail2ban-notifications"

  tags = {
    Name = "waf-fail2ban-notifications"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "waf_notifications_policy" {
  arn = aws_sns_topic.waf_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.waf_notifications.arn
      }
    ]
  })
}

# Email subscription (if email provided)
resource "aws_sns_topic_subscription" "email_notification" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.waf_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Lambda function for Slack notifications
resource "aws_lambda_function" "slack_notifier" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  filename      = "slack_notifier.zip"
  function_name = "waf-slack-notifier"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = {
    Name = "waf-slack-notifier"
  }

  depends_on = [data.archive_file.slack_notifier_zip[0]]
}

# Lambda ZIP file
data "archive_file" "slack_notifier_zip" {
  count       = var.slack_webhook_url != "" ? 1 : 0
  type        = "zip"
  output_path = "slack_notifier.zip"
  
  source {
    content = templatefile("${path.module}/lambda/slack_notifier.py", {
      webhook_url = var.slack_webhook_url
    })
    filename = "index.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  count = var.slack_webhook_url != "" ? 1 : 0
  name  = "waf-slack-notifier-role"

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

  tags = {
    Name = "waf-slack-notifier-role"
  }
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  count = var.slack_webhook_url != "" ? 1 : 0
  name  = "waf-slack-notifier-policy"
  role  = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# SNS subscription for Lambda (if Slack webhook provided)
resource "aws_sns_topic_subscription" "slack_notification" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.waf_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

# Lambda permission for SNS
resource "aws_lambda_permission" "sns_invoke" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.waf_notifications.arn
}
