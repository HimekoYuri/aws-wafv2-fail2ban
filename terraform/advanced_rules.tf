# =============================================================================
# 高度なWAFルール定義 (2026年最新化)
# - OWASP Top 10:2026対応
# - AI駆動攻撃対策
# - rate_based_statement構文修正 (and_statement内不可の制約対応)
# =============================================================================

locals {
  # 段階的制裁の閾値設定
  stage1_threshold = var.count_threshold
  stage2_threshold = var.rate_limit_requests
  stage3_threshold = var.rate_limit_requests * 2
  stage4_threshold = var.rate_limit_requests * 3
}

# WAFv2 Web ACL with Advanced Rules
resource "aws_wafv2_web_acl" "fail2ban_advanced_acl" {
  name  = "fail2ban-advanced-waf-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # =====================================================
  # Rule 1: WhiteList - 永久にBANしない (最高優先度)
  # =====================================================
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

  # =====================================================
  # Rule 2: BlackList - ずっとBANする
  # =====================================================
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

  # =====================================================
  # Rule 3: 従来型攻撃パターン検知 (SQLi, XSS, Traversal, RCE)
  # =====================================================
  rule {
    name     = "AttackPatternRule"
    priority = 3

    action {
      block {
        custom_response {
          response_code = 403
          custom_response_body_key = "blocked"
        }
      }
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
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 1
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
            text_transformation {
              priority = 1
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.attack_patterns.arn
            field_to_match {
              body {
                oversize_handling = "MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 1
              type     = "LOWERCASE"
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

  # =====================================================
  # Rule 4: 2026年新規脅威パターン (SSRF, NoSQLi, Log4Shell, GraphQL)
  # =====================================================
  rule {
    name     = "ModernAttackPatternRule"
    priority = 4

    action {
      block {
        custom_response {
          response_code = 403
          custom_response_body_key = "blocked"
        }
      }
    }

    statement {
      or_statement {
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.modern_attack_patterns.arn
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 1
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.modern_attack_patterns.arn
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 0
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 1
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.modern_attack_patterns.arn
            field_to_match {
              all_query_arguments {}
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
      metric_name                = "ModernAttackPatternRule"
      sampled_requests_enabled   = true
    }
  }

  # =====================================================
  # Rule 5: 疑わしいUser-Agent検知 (AI自動化ツール対応)
  # =====================================================
  rule {
    name     = "SuspiciousUserAgentRule"
    priority = 5

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

  # =====================================================
  # Rule 6: Stage 1 - 警告レベル (Count)
  # =====================================================
  rule {
    name     = "Stage1WarningRule"
    priority = 6

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

  # =====================================================
  # Rule 7: Stage 2 - 軽度制限 (Block)
  # =====================================================
  rule {
    name     = "Stage2LightBlockRule"
    priority = 7

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

  # =====================================================
  # Rule 8: Stage 3 - 再犯者への重度制限
  # NOTE: rate_based_statementはand_statement内に配置不可のため
  #       scope_down_statementでIP Set参照に変更
  # =====================================================
  rule {
    name     = "Stage3RepeatOffenderRule"
    priority = 8

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = local.stage3_threshold
        aggregate_key_type = "IP"

        scope_down_statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.repeat_offenders.arn
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

  # =====================================================
  # Rule 9: Stage 4 - 重度犯罪者への最重度制限
  # =====================================================
  rule {
    name     = "Stage4HeavyOffenderRule"
    priority = 9

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = local.stage4_threshold
        aggregate_key_type = "IP"

        scope_down_statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.heavy_offenders.arn
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

  # =====================================================
  # Rule 10: 大量リクエストヘッダー検知 (HTTP Flood / Slowloris対策)
  # =====================================================
  rule {
    name     = "OversizedHeaderRule"
    priority = 10

    action {
      block {}
    }

    statement {
      size_constraint_statement {
        field_to_match {
          headers {
            match_pattern {
              all {}
            }
            match_scope      = "ALL"
            oversize_handling = "MATCH"
          }
        }
        comparison_operator = "GT"
        size                = 8192
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "OversizedHeaderRule"
      sampled_requests_enabled   = true
    }
  }

  # カスタムレスポンスボディ定義
  custom_response_body {
    key          = "blocked"
    content      = "{\"error\": \"Access Denied\", \"code\": 403}"
    content_type = "APPLICATION_JSON"
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
