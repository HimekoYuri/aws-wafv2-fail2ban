# 既存のIP Set（ホワイトリスト・ブラックリスト）
resource "aws_wafv2_ip_set" "whitelist" {
  name               = "fail2ban-whitelist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips

  tags = {
    Name = "fail2ban-whitelist"
  }
}

resource "aws_wafv2_ip_set" "blacklist" {
  name               = "fail2ban-blacklist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blacklist_ips

  tags = {
    Name = "fail2ban-blacklist"
  }
}

# 段階的制裁システム用のIP Set
resource "aws_wafv2_ip_set" "repeat_offenders" {
  name               = "fail2ban-repeat-offenders"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = []

  tags = {
    Name = "fail2ban-repeat-offenders"
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
}