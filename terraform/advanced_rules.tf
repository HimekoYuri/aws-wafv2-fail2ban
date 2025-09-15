# 高度なWAFルール定義
locals {
  # 段階的制裁の閾値設定
  stage1_threshold = var.count_threshold          # 警告レベル
  stage2_threshold = var.rate_limit_requests      # 軽度制限
  stage3_threshold = var.rate_limit_requests * 2  # 重度制限（再犯者）
  stage4_threshold = var.rate_limit_requests * 3  # 最重度制限
}

# WAFv2 Web ACL with Advanced Rules
resource "aws_wafv2_web_acl" "fail2ban_advanced_acl" {
  name  = "fail2ban-advanced-waf-acl"
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

  # Rule 3: 攻撃パターン検知 - 正規表現ベース
  rule {
    name     = "AttackPatternRule"
    priority = 3

    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.attack_patterns.arn
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.attack_patterns.arn
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 0
              type     = "URL_DECODE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AttackPatternRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: 疑わしいUser-Agent検知
  rule {
    name     = "SuspiciousUserAgentRule"
    priority = 4

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.suspicious_user_agents.arn
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SuspiciousUserAgentRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: Stage 1 - 警告レベル (Count)
  rule {
    name     = "Stage1WarningRule"
    priority = 5

    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = local.stage1_threshold
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
      metric_name                = "Stage1WarningRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 6: Stage 2 - 軽度制限 (Block)
  rule {
    name     = "Stage2LightBlockRule"
    priority = 6

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = local.stage2_threshold
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
      metric_name                = "Stage2LightBlockRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 7: Stage 3 - 再犯者への重度制限
  rule {
    name     = "Stage3RepeatOffenderRule"
    priority = 7

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.repeat_offenders.arn
          }
        }
        statement {
          rate_based_statement {
            limit              = local.stage3_threshold
            aggregate_key_type = "IP"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Stage3RepeatOffenderRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 8: Stage 4 - 重度犯罪者への最重度制限
  rule {
    name     = "Stage4HeavyOffenderRule"
    priority = 8

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.heavy_offenders.arn
          }
        }
        statement {
          rate_based_statement {
            limit              = local.stage4_threshold
            aggregate_key_type = "IP"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Stage4HeavyOffenderRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "fail2banAdvancedWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "fail2ban-advanced-waf-acl"
  }
}