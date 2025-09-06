# WAFv2 Web ACL for CloudFront
resource "aws_wafv2_web_acl" "fail2ban_acl" {
  name  = "fail2ban-waf-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate-based rule for fail2ban-like functionality
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_requests
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string = var.target_path
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "STARTS_WITH"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Additional security rules
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "fail2banWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "fail2ban-waf-acl"
  }
}

# CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "/aws/wafv2/fail2ban"
  retention_in_days = 30

  tags = {
    Name = "fail2ban-waf-logs"
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  resource_arn            = aws_wafv2_web_acl.fail2ban_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# CloudWatch Alarm for high rate limit triggers
resource "aws_cloudwatch_metric_alarm" "rate_limit_alarm" {
  alarm_name          = "waf-rate-limit-high-triggers"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors WAF rate limit rule triggers"
  alarm_actions       = []

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_acl.name
    Rule   = "RateLimitRule"
  }

  tags = {
    Name = "waf-rate-limit-alarm"
  }
}
