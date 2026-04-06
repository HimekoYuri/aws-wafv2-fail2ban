# =============================================================================
# IP Set定義 (IPv4 + IPv6 対応)
# =============================================================================

# ホワイトリスト (IPv4)
resource "aws_wafv2_ip_set" "whitelist" {
  name               = "fail2ban-whitelist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips

  tags = {
    Name = "fail2ban-whitelist"
  }
}

# ブラックリスト (IPv4)
resource "aws_wafv2_ip_set" "blacklist" {
  name               = "fail2ban-blacklist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blacklist_ips

  tags = {
    Name = "fail2ban-blacklist"
  }
}

# 段階的制裁システム用 IP Set
resource "aws_wafv2_ip_set" "repeat_offenders" {
  name               = "fail2ban-repeat-offenders"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = []

  tags = {
    Name = "fail2ban-repeat-offenders"
  }

  lifecycle {
    ignore_changes = [addresses]
  }
}

resource "aws_wafv2_ip_set" "heavy_offenders" {
  name               = "fail2ban-heavy-offenders"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = []

  tags = {
    Name = "fail2ban-heavy-offenders"
  }

  lifecycle {
    ignore_changes = [addresses]
  }
}
