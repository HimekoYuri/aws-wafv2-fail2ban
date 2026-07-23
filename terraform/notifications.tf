# =============================================================================
# 通知システム (SNS + Slack + Teams)
# =============================================================================

# SNS Topic
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
        Sid    = "AllowCloudWatchPublish"
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

# Email subscription
resource "aws_sns_topic_subscription" "email_notification" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.waf_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# =============================================================================
# Slack通知 Lambda
# =============================================================================

data "archive_file" "slack_notifier_zip" {
  count       = var.slack_webhook_url != "" ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/slack_notifier.py"
  output_path = "${path.module}/lambda/slack_notifier.zip"
}

resource "aws_lambda_function" "slack_notifier" {
  count            = var.slack_webhook_url != "" ? 1 : 0
  filename         = data.archive_file.slack_notifier_zip[0].output_path
  function_name    = "waf-slack-notifier"
  role             = aws_iam_role.lambda_role[0].arn
  handler          = "slack_notifier.handler"
  runtime          = var.lambda_python_runtime
  timeout          = 30
  source_code_hash = data.archive_file.slack_notifier_zip[0].output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SLACK_CHANNEL     = var.slack_channel
    }
  }

  tags = {
    Name = "waf-slack-notifier"
  }
}

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
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "slack_notification" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.waf_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

resource "aws_lambda_permission" "sns_invoke" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.waf_notifications.arn
}

# =============================================================================
# Teams通知 Lambda
# =============================================================================

data "archive_file" "teams_notifier_zip" {
  count       = var.teams_webhook_url != "" ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/teams_notifier.py"
  output_path = "${path.module}/lambda/teams_notifier.zip"
}

resource "aws_lambda_function" "teams_notifier" {
  count            = var.teams_webhook_url != "" ? 1 : 0
  filename         = data.archive_file.teams_notifier_zip[0].output_path
  function_name    = "waf-teams-notifier"
  role             = aws_iam_role.teams_lambda_role[0].arn
  handler          = "teams_notifier.handler"
  runtime          = var.lambda_python_runtime
  timeout          = 30
  source_code_hash = data.archive_file.teams_notifier_zip[0].output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TEAMS_WEBHOOK_URL = var.teams_webhook_url
    }
  }

  tags = {
    Name = "waf-teams-notifier"
  }
}

resource "aws_iam_role" "teams_lambda_role" {
  count = var.teams_webhook_url != "" ? 1 : 0
  name  = "waf-teams-notifier-role"

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
    Name = "waf-teams-notifier-role"
  }
}

resource "aws_iam_role_policy" "teams_lambda_policy" {
  count = var.teams_webhook_url != "" ? 1 : 0
  name  = "waf-teams-notifier-policy"
  role  = aws_iam_role.teams_lambda_role[0].id

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
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "teams_notification" {
  count     = var.teams_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.waf_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.teams_notifier[0].arn
}

resource "aws_lambda_permission" "teams_sns_invoke" {
  count         = var.teams_webhook_url != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.teams_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.waf_notifications.arn
}
