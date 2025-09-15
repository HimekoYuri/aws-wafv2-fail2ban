# 攻撃パターン検知アラーム
resource "aws_cloudwatch_metric_alarm" "attack_pattern_alarm" {
  alarm_name          = "waf-attack-pattern-detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Attack patterns detected - potential security threat"
  alarm_actions       = [aws_sns_topic.waf_notifications.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_advanced_acl.name
    Rule   = "AttackPatternRule"
  }

  tags = {
    Name = "waf-attack-pattern-alarm"
  }
}

# 疑わしいUser-Agent検知アラーム
resource "aws_cloudwatch_metric_alarm" "suspicious_user_agent_alarm" {
  alarm_name          = "waf-suspicious-user-agent-detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Suspicious User-Agent detected - potential bot activity"
  alarm_actions       = [aws_sns_topic.waf_notifications.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_advanced_acl.name
    Rule   = "SuspiciousUserAgentRule"
  }

  tags = {
    Name = "waf-suspicious-user-agent-alarm"
  }
}

# Stage 1 警告レベルアラーム
resource "aws_cloudwatch_metric_alarm" "stage1_warning_alarm" {
  alarm_name          = "waf-stage1-warning-threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AllowedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.count_threshold
  alarm_description   = "Stage 1 warning threshold exceeded - monitoring suspicious activity"
  alarm_actions       = [aws_sns_topic.waf_notifications.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_advanced_acl.name
    Rule   = "Stage1WarningRule"
  }

  tags = {
    Name = "waf-stage1-warning-alarm"
  }
}

# Stage 2 軽度制限アラーム
resource "aws_cloudwatch_metric_alarm" "stage2_block_alarm" {
  alarm_name          = "waf-stage2-light-block"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Stage 2 light blocking activated - IP will be added to repeat offenders"
  alarm_actions       = [aws_sns_topic.waf_notifications.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_advanced_acl.name
    Rule   = "Stage2LightBlockRule"
  }

  tags = {
    Name = "waf-stage2-block-alarm"
  }
}

# Stage 3 再犯者制限アラーム
resource "aws_cloudwatch_metric_alarm" "stage3_repeat_offender_alarm" {
  alarm_name          = "waf-stage3-repeat-offender-block"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Stage 3 repeat offender blocking - IP will be escalated to heavy offenders"
  alarm_actions       = [aws_sns_topic.waf_notifications.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_advanced_acl.name
    Rule   = "Stage3RepeatOffenderRule"
  }

  tags = {
    Name = "waf-stage3-repeat-offender-alarm"
  }
}

# Stage 4 重度犯罪者制限アラーム
resource "aws_cloudwatch_metric_alarm" "stage4_heavy_offender_alarm" {
  alarm_name          = "waf-stage4-heavy-offender-block"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Stage 4 heavy offender blocking - maximum security level activated"
  alarm_actions       = [aws_sns_topic.waf_notifications.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.fail2ban_advanced_acl.name
    Rule   = "Stage4HeavyOffenderRule"
  }

  tags = {
    Name = "waf-stage4-heavy-offender-alarm"
  }
}