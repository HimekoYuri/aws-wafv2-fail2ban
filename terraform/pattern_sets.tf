# 攻撃パターン検知用の正規表現セット
resource "aws_wafv2_regex_pattern_set" "attack_patterns" {
  name  = "fail2ban-attack-patterns"
  scope = "CLOUDFRONT"

  # SQLインジェクション攻撃パターン
  regular_expression {
    regex_string = ".*(union|select|insert|update|delete|drop|create|alter|exec|execute).*"
  }

  # XSS攻撃パターン
  regular_expression {
    regex_string = ".*(<script|javascript:|onload=|onerror=|onclick=).*"
  }

  # ディレクトリトラバーサル攻撃
  regular_expression {
    regex_string = ".*(\\.\\.[\\/\\\\]|\\.\\.%2f|\\.\\.%5c).*"
  }

  # 悪意のあるファイル拡張子
  regular_expression {
    regex_string = ".*\\.(php|asp|aspx|jsp|cgi|pl)([\\?\\&].*)?$"
  }

  # コマンドインジェクション
  regular_expression {
    regex_string = ".*(;|\\||&|`|\\$\\(|\\${).*"
  }

  tags = {
    Name = "fail2ban-attack-patterns"
  }
}

# 疑わしいUser-Agentパターン
resource "aws_wafv2_regex_pattern_set" "suspicious_user_agents" {
  name  = "fail2ban-suspicious-user-agents"
  scope = "CLOUDFRONT"

  # 自動化ツール
  regular_expression {
    regex_string = ".*(bot|crawler|spider|scraper|scanner|curl|wget|python|perl).*"
  }

  # 空のUser-Agent
  regular_expression {
    regex_string = "^$"
  }

  # 短すぎるUser-Agent
  regular_expression {
    regex_string = "^.{1,10}$"
  }

  tags = {
    Name = "fail2ban-suspicious-user-agents"
  }
}