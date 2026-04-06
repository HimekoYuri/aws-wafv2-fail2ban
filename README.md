# AWS WAFv2 Advanced Fail2ban Integration

AWS WAFv2を使用した高度なfail2ban機能とIP管理システム

## 概要

AWS WAFv2を使用してfail2banのような機能を実現し、CloudFront + S3で構成されたWebサイトのセキュリティを強化するソリューションです。

**TerraformとCloudFormationの両方に対応**

## 2026年4月 最新化内容

- OWASP Top 10:2026対応 (SSRF統合、サプライチェーン、AI脅威)
- AI駆動攻撃・自動化ツール検知パターン追加
- NoSQLインジェクション、GraphQLインジェクション、Log4Shell対策
- プロトタイプ汚染、エンコーディング回避攻撃対策
- HTTP Flood / Slowloris対策 (大量ヘッダー検知)
- Terraform `>= 1.6` / AWS Provider `~> 5.80` 対応
- CloudFormation: Teams通知、IP Manager Lambda、段階的制裁を統合
- Lambda: Python 3.13、型ヒント、構造化ログ、TTL自動期限切れ
- Teams通知: Adaptive Card形式 (MessageCard非推奨対応)
- rate_based_statement構文バグ修正 (and_statement内不可の制約対応)
- 正規表現パターンのエスケープ修正
- IAMポリシーの最小権限化

## プロジェクト構成

```
aws-wafv2-fail2ban/
├── terraform/              # Terraformファイル
│   ├── main.tf            # レガシーWAF ACL (後方互換)
│   ├── advanced_rules.tf  # 高度なWAFルール (メイン)
│   ├── pattern_sets.tf    # 正規表現パターン定義
│   ├── ip_sets.tf         # IP Set定義
│   ├── advanced_alarms.tf # CloudWatchアラーム
│   ├── notifications.tf   # SNS + Slack + Teams通知
│   ├── lambda_functions.tf # IP Manager Lambda
│   ├── lambda/            # Lambda関数ソース
│   └── terraform.tfvars.example
├── cloudformation/         # CloudFormationファイル
│   ├── waf-fail2ban.yaml  # 統合テンプレート
│   ├── parameters.json    # パラメータ
│   └── deploy.sh          # デプロイスクリプト
├── scripts/               # 運用スクリプト
└── Makefile
```

## 主要機能

### 攻撃パターン検知
- SQLインジェクション (UNION-based, stacked, blind)
- XSS (DOM-based, reflected, stored, SVG)
- ディレクトリトラバーサル + エンコーディング回避
- コマンドインジェクション
- SSRF (AWS metadata, GCP, Azure)
- NoSQLインジェクション / プロトタイプ汚染
- GraphQLインジェクション / イントロスペクション乱用
- Log4Shell / JNDI系攻撃
- HTTP Flood / Slowloris (大量ヘッダー)

### AI駆動攻撃対策 (2026年新規)
- AI自動スキャナ検知 (GPT-crawler, LLM-agent等)
- 自動化エクスプロイトツール検知
- ヘッドレスブラウザ / Playwright / Crawl4AI検知

### 段階的制裁システム
- Stage 1: 警告 (Count) → アラート発生
- Stage 2: 軽度制限 (Block) → 再犯者リスト追加
- Stage 3: 再犯者制限 → 重度犯罪者リスト追加
- Stage 4: 重度犯罪者制限 → 最重度制裁

### 自動IP管理
- Lambda関数による動的IP Set更新
- TTL自動期限切れ (デフォルト24時間)
- WAFv2 OptimisticLock リトライ対応

## クイックスタート

### Terraform
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# terraform.tfvarsを編集
make init
make plan
make apply
```

### CloudFormation
```bash
# parameters.jsonを編集
cd cloudformation
./deploy.sh
```

## 設定項目

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| count_threshold | 100 | Stage 1 警告閾値 |
| rate_limit_requests | 500 | Stage 2 ブロック閾値 |
| ip_ttl_hours | 24 | IP自動期限切れ (時間) |
| lambda_python_runtime | python3.13 | Lambda Pythonバージョン |
| enable_ai_attack_protection | true | AI攻撃対策 |
| enable_api_abuse_protection | true | API乱用対策 |
