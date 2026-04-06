# =============================================================================
# 攻撃パターン検知用の正規表現セット (2026年攻撃動向対応)
# OWASP Top 10:2026 + AI駆動攻撃 + API乱用対策
# =============================================================================

# --- 従来型攻撃パターン (SQLi, XSS, Traversal, RCE) ---
resource "aws_wafv2_regex_pattern_set" "attack_patterns" {
  name  = "fail2ban-attack-patterns"
  scope = "CLOUDFRONT"

  # SQLインジェクション (UNION-based, stacked queries, blind)
  regular_expression {
    regex_string = "(?i)(?:union\\s+(?:all\\s+)?select|select\\s+.*from|insert\\s+into|update\\s+.*set|delete\\s+from|drop\\s+(?:table|database)|alter\\s+table|exec(?:ute)?\\s)"
  }

  # XSS攻撃パターン (DOM-based, reflected, stored)
  regular_expression {
    regex_string = "(?i)(?:<script|javascript\\s*:|on(?:load|error|click|mouseover|focus|blur)\\s*=|<iframe|<object|<embed|<svg\\s+on)"
  }

  # ディレクトリトラバーサル + パスインジェクション
  regular_expression {
    regex_string = "(?:\\.\\.[\\/\\\\]|\\.\\.%2[fF]|\\.\\.%5[cC]|%2[eE]%2[eE][\\/\\\\])"
  }

  # サーバサイドコード実行 (拡張子ベース)
  regular_expression {
    regex_string = "(?i)\\.(?:php[0-9]?|asp[x]?|jsp[x]?|cgi|pl|py|rb|sh|bash|cmd|ps1)(?:[?&#]|$)"
  }

  # コマンドインジェクション (OS command, shell meta)
  regular_expression {
    regex_string = "(?:[;&|]|\\$\\(|\\$\\{|`|\\|\\||&&)"
  }

  tags = {
    Name = "fail2ban-attack-patterns"
  }
}

# --- 2026年新規脅威パターン (AI駆動攻撃, API乱用, SSRF) ---
resource "aws_wafv2_regex_pattern_set" "modern_attack_patterns" {
  name  = "fail2ban-modern-attack-patterns"
  scope = "CLOUDFRONT"

  # SSRF (Server-Side Request Forgery) - OWASP 2026 A01統合
  regular_expression {
    regex_string = "(?i)(?:169\\.254\\.169\\.254|metadata\\.google|100\\.100\\.100\\.200|fd00:ec2::254)"
  }

  # プロトタイプ汚染 / NoSQLインジェクション
  regular_expression {
    regex_string = "(?i)(?:__proto__|constructor\\s*\\[|\\$(?:gt|gte|lt|lte|ne|in|nin|regex|where|exists)\\s*:)"
  }

  # GraphQLインジェクション / イントロスペクション乱用
  regular_expression {
    regex_string = "(?i)(?:__schema|__type|introspectionquery|mutation\\s*\\{.*delete|mutation\\s*\\{.*drop)"
  }

  # Log4Shell / JNDI系攻撃 (継続的脅威)
  regular_expression {
    regex_string = "(?i)(?:\\$\\{jndi:|\\$\\{lower:|\\$\\{upper:|\\$\\{env:|\\$\\{sys:)"
  }

  # パストラバーサル via エンコーディング回避
  regular_expression {
    regex_string = "(?:%00|%0[aAdD]|%25(?:2[eEfF]|5[cC])|\\\\x[0-9a-fA-F]{2})"
  }

  tags = {
    Name = "fail2ban-modern-attack-patterns"
  }
}

# --- 疑わしいUser-Agentパターン (AI自動化ツール対応) ---
resource "aws_wafv2_regex_pattern_set" "suspicious_user_agents" {
  name  = "fail2ban-suspicious-user-agents"
  scope = "CLOUDFRONT"

  # 従来型スキャナ・ボット
  regular_expression {
    regex_string = "(?i)(?:nikto|sqlmap|nmap|masscan|zap|burp|dirbuster|gobuster|wfuzz|ffuf|nuclei|httpx)"
  }

  # AI駆動スキャナ・自動化ツール (2026年新規)
  regular_expression {
    regex_string = "(?i)(?:ai-scanner|gpt-crawler|llm-agent|auto-exploit|pentest-ai|chatgpt-plugin|anthropic-fetcher)"
  }

  # 汎用スクレイパー・クローラー
  regular_expression {
    regex_string = "(?i)(?:scrapy|mechanize|phantomjs|headless|selenium|puppeteer|playwright|crawl4ai)"
  }

  # 短すぎるまたは空のUser-Agent
  regular_expression {
    regex_string = "^.{0,5}$"
  }

  tags = {
    Name = "fail2ban-suspicious-user-agents"
  }
}
