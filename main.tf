# IP Set for WhiteList (永久にBANしない)
resource "aws_wafv2_ip_set" "whitelist" {
  name               = "fail2ban-whitelist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips

  tags = {
    Name = "fail2ban-whitelist"
  }
}

# IP Set for BlackList (ずっとBANする)
resource "aws_wafv2_ip_set" "blacklist" {
  name               = "fail2ban-blacklist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blacklist_ips

  tags = {
    Name = "fail2ban-blacklist"
  }
}

# WAFv2 Web ACL for CloudFront
resource "aws_wafv2_web_acl" "fail2ban_acl" {
  name  = "fail2ban-waf-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: WhiteList - 永久にBANしない (最高優先度)
  rule {
    name     = "WhiteListRule"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.whitelist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WhiteListRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: BlackList - ずっとBANする
  rule {
    name     = "BlackListRule"
    priority = 2

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blacklist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlackListRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Count Rule - 閾値監視用
  rule {
    name     = "CountRule"
    priority = 3

    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = var.count_threshold
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
      metric_name                = "CountRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Block Rule - 実際のブロック用
  rule {
    name     = "BlockRule"
    priority = 4

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
      metric_name                = "BlockRule"
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

# CloudWatch Alarm for Count Rule threshold exceeded
resource "aws_cloudwatch_metric_alarm" "count_threshold_alarm" {
  alarm_name          = "waf-count-threshold-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AllowedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.count_threshold
  alarm_description   = "Count rule threshold exceeded - potential attack detected"
  alarm_actions       = []

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_acl.name
    Rule   = "CountRule"
  }

  tags = {
    Name = "waf-count-threshold-alarm"
  }
}

# CloudWatch Alarm for Block Rule triggered (IP added to block list)
resource "aws_cloudwatch_metric_alarm" "block_added_alarm" {
  alarm_name          = "waf-ip-blocked-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "IP address has been blocked by rate limiting rule"
  alarm_actions       = []

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_acl.name
    Rule   = "BlockRule"
  }

  tags = {
    Name = "waf-ip-blocked-alarm"
  }
}

# CloudWatch Alarm for Block Rule cleared (IP removed from block list)
resource "aws_cloudwatch_metric_alarm" "block_cleared_alarm" {
  alarm_name          = "waf-ip-unblocked-alert"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "IP address block has been cleared"
  alarm_actions       = []
  treat_missing_data  = "breaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_acl.name
    Rule   = "BlockRule"
  }

  tags = {
    Name = "waf-ip-unblocked-alarm"
  }
}
