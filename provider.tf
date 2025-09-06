provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "aws-wafv2-fail2ban"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
