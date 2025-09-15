# AWS WAFv2 Advanced Fail2ban Integration

AWS WAFv2を使用した高度なfail2ban機能とIP管理システム

## 概要

このプロジェクトは、AWS WAFv2を使用してfail2banのような機能を実現し、CloudFront + S3で構成されたWebサイトのセキュリティを強化するためのソリューションです。WhiteList/BlackList機能、段階的な監視・ブロック機能、詳細なアラート機能を提供します。

**TerraformとCloudFormationの両方に対応**しており、お好みのIaCツールを選択できます。

## プロジェクト構成

```
aws-wafv2-fail2ban/
├── terraform/              # Terraformファイル
│   ├── *.tf               # Terraform設定ファイル
│   ├── lambda/            # Lambda関数
│   └── terraform.tfvars.example
├── cloudformation/         # CloudFormationファイル
│   ├── waf-fail2ban.yaml  # CloudFormationテンプレート
│   ├── parameters.json    # パラメータファイル
│   ├── deploy.sh          # デプロイスクリプト
│   └── README.md          # CloudFormation用ドキュメント
├── scripts/               # 運用スクリプト
│   ├── test.sh           # テストスクリプト
│   └── deploy.sh         # Terraformデプロイスクリプト
├── Makefile              # Make操作定義
└── README.md             # このファイル
```

## 主要機能

### 🚀 **NEW! 高度な機能（v5.0.0）**

1. **🔍 ログパターンマッチング機能**
   - 正規表現ベースの攻撃パターン検知
   - SQLインジェクション、XSS、ディレクトリトラバーサル対応
   - 疑わしいUser-Agent検知

2. **🎯 段階的制裁システム**
   - Stage 1: 警告レベル（Count）
   - Stage 2: 軽度制限（Block）→ 再犯者リスト追加
   - Stage 3: 再犯者制限（重度Block）→ 重度犯罪者リスト追加
   - Stage 4: 重度犯罪者制限（最重度Block）

3. **🤖 自動IP管理**
   - Lambda関数による動的IP Set更新
   - 再犯者の自動エスカレーション
   - CloudWatch Logsとの連携

### 🛡️ 基本の4段階セキュリティルール

1. **WhiteList Rule (優先度1)** - 永久にBANしない
   - 信頼できるIPアドレスを永続的に許可
   - 最高優先度で他のルールをバイパス

2. **BlackList Rule (優先度2)** - ずっとBANする  
   - 悪意のあるIPアドレスを永続的にブロック
   - 手動管理による確実な遮断

3. **Count Rule (優先度3)** - 閾値監視用
   - 設定した閾値でカウントのみ実行
   - アラート発生のトリガーとして機能

4. **Block Rule (優先度4)** - 実際のブロック用
   - 閾値超過時に自動的にIPをブロック
   - 一定時間後に自動解除

### 📊 詳細な監視・アラート機能

- **Count Threshold Alert**: Count値が閾値を超えた際のアラート
- **IP Blocked Alert**: IPがブロックリストに追加された際のアラート  
- **IP Unblocked Alert**: IPがブロックリストから解除された際のアラート
- **SNS通知**: Email配信
- **Slack通知**: 指定チャンネルへの通知
- **Microsoft Teams通知**: 指定チャンネルへの通知

### 🎯 対象パス設定

- `/website`配下の全てのURI（サブパス含む）に対応
- 例: `/website/`, `/website/download`, `/website/api/v1` など

## クイックスタート

### 前提条件

- **共通**
  - AWS CLI設定済み（AWS SSO対応）
  - 適切なIAM権限
  - 既存のCloudFront Distribution

- **Terraform使用時**
  - Terraform >= 1.0

- **CloudFormation使用時**
  - AWS CLI >= 2.0

### 🚀 **NEW! 高度な機能を有効化**

新機能（パターンマッチング・段階的制裁）を使用する場合：

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集して以下を追加
echo 'enable_advanced_rules = true' >> terraform.tfvars
echo 'enable_user_agent_filtering = true' >> terraform.tfvars
```

詳細は [`ADVANCED_FEATURES.md`](./ADVANCED_FEATURES.md) をご確認ください。

### 設定ファイルの作成

#### Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集して環境に合わせて設定
```

#### CloudFormation
```bash
cd cloudformation
# parameters.jsonを編集して環境に合わせて設定
```

## デプロイ方法

### 🚀 Terraform（推奨）

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集
make init
make plan
make apply
```

または、スクリプトを使用：
```bash
./scripts/deploy.sh
```

### 🚀 CloudFormation

```bash
cd cloudformation
# parameters.jsonを編集
./deploy.sh
```

### 🧪 テスト実行

```bash
./scripts/test.sh
```

## 設定パラメータ

| パラメータ | デフォルト値 | 説明 |
|-----------|-------------|------|
| `aws_region` | "us-east-1" | AWSリージョン（CloudFrontはus-east-1必須） |
| `aws_profile` | "default" | AWSプロファイル名 |
| `environment` | "production" | 環境名 |
| `domain_name` | "" | ドメイン名 |
| `cloudfront_distribution_id` | "" | CloudFront Distribution ID |
| `count_threshold` | 50 | Count閾値（アラート発生） |
| `rate_limit_requests` | 100 | Block閾値（ブロック実行） |
| `block_duration_seconds` | 3600 | ブロック継続時間（秒） |
| `target_path` | "/website" | 監視対象のパス |
| `whitelist_ips` | [] | ホワイトリストIP一覧 |
| `blacklist_ips` | [] | ブラックリストIP一覧 |
| `enable_managed_rules` | false | AWS Managed Rules有効化 |
| `notification_email` | "" | SNS通知用メールアドレス |
| `slack_webhook_url` | "" | Slack Webhook URL |
| `slack_channel` | "aws_system_notify" | Slackチャンネル名 |
| `teams_webhook_url` | "" | Microsoft Teams Webhook URL |
| `enable_advanced_rules` | false | 高度なパターンマッチング機能有効化 |
| `enable_user_agent_filtering` | false | 疑わしいUser-Agent検知有効化 |
| `lambda_python_runtime` | "python3.13" | Lambda関数のPythonランタイムバージョン |

## アーキテクチャ

```
Internet → CloudFront → WAFv2 → S3
                ↓
    [WhiteList] → Allow (永久許可)
         ↓
    [BlackList] → Block (永久拒否)  
         ↓
    [Count Rule] → Count (閾値監視)
         ↓
    [Block Rule] → Block (一時拒否)
         ↓
    CloudWatch Logs & Alarms
         ↓
    SNS → Email & Slack & Teams通知
```

## 監視とアラート

### CloudWatch Logs
- **ロググループ**: `/aws/wafv2/fail2ban`
- **保持期間**: 30日
- **機密情報**: 除外済み

### CloudWatch Alarms

1. **Count Threshold Alarm** (`waf-count-threshold-exceeded`)
   - Count値が閾値を超えた際のアラート
   
2. **IP Blocked Alarm** (`waf-ip-blocked-alert`)
   - IPがブロックリストに追加された際のアラート
   
3. **IP Unblocked Alarm** (`waf-ip-unblocked-alert`)
   - IPがブロックリストから解除された際のアラート

### 通知システム
- **SNS Topic**: `waf-fail2ban-notifications`
- **Email通知**: 設定したメールアドレスに配信
- **Slack通知**: 指定チャンネルに配信
- **Teams通知**: 指定チャンネルに配信

## セキュリティ考慮事項

### ⚠️ 重要な注意事項

- **AWS Managed Rules**: デフォルトで無効化されています
  - 脆弱性リスクが高くなる可能性があります
  - 本番環境では`enable_managed_rules = true`を検討してください
  - 定期的なセキュリティ監査を実施してください

### 🔒 セキュリティベストプラクティス

- **機密情報の管理**
  - Webhook URLは環境変数やSecrets Managerで管理
  - terraform.tfvarsはGitにコミットしない
  
- **アクセス制御**
  - 最小権限の原則に従ったIAM権限設定
  - CloudFront Distribution IDの適切な管理

- **監視とログ**
  - CloudWatch Logsの定期的な確認
  - アラートの適切な設定と対応手順の整備

## トラブルシューティング

### よくある問題

1. **CloudFrontとの関連付けエラー**
   ```
   Error: WAF ACL association failed
   ```
   - Web ACLのスコープが`CLOUDFRONT`であることを確認
   - us-east-1リージョンでの作成を確認
   - CloudFront Distribution IDが正しいことを確認

2. **通知が届かない**
   ```
   Error: SNS publish failed
   ```
   - SNS Topic Policyの設定を確認
   - Slack/Teams Webhook URLの有効性を確認
   - Lambda関数のログを確認

3. **Terraformエラー**
   ```
   Error: terraform plan failed
   ```
   - `terraform init`を実行
   - プロバイダーのバージョンを確認
   - AWS認証情報を確認

4. **Lambda関数エラー**
   ```
   Error: Lambda function timeout
   ```
   - Python runtime バージョンを確認
   - 依存関係の問題を確認
   - CloudWatch Logsでエラー詳細を確認

### デバッグ手順

```bash
# Terraformの場合
cd terraform
terraform plan -detailed-exitcode
terraform validate

# テストスクリプトの実行
./scripts/test.sh

# CloudWatch Logsの確認
aws logs describe-log-groups --log-group-name-prefix "/aws/wafv2"
```

## 運用・保守

### 定期メンテナンス

- **月次**
  - CloudWatch Logsの確認
  - アラート履歴の確認
  - IP リストの見直し

- **四半期**
  - セキュリティ設定の見直し
  - Lambda runtime の更新確認
  - 閾値設定の最適化

### アップデート手順

1. **Python runtime更新**
   ```bash
   # terraform.tfvarsで更新
   lambda_python_runtime = "python3.14"  # 新バージョン
   
   # 適用
   terraform plan
   terraform apply
   ```

2. **設定変更**
   ```bash
   # 設定ファイル編集後
   terraform plan
   terraform apply
   ```

## ライセンス

MIT License

## 貢献

プルリクエストやイシューの報告を歓迎します。

### 貢献ガイドライン

1. **Issue作成**: バグ報告や機能要望
2. **Pull Request**: 機能追加や修正
3. **セキュリティ**: セキュリティに関する問題は直接メンテナーにご連絡ください

### 開発環境セットアップ

```bash
# リポジトリクローン
git clone https://github.com/HimekoYuri/aws-wafv2-fail2ban.git
cd aws-wafv2-fail2ban

# 依存関係インストール
# Terraform
terraform version

# AWS CLI
aws --version

# テスト実行
./scripts/test.sh
```

## 更新履歴

- **v5.0.0** (2025-01-XX)
  - 🚀 高度なパターンマッチング機能追加
  - 🎯 段階的制裁システム実装
  - 🤖 自動IP管理Lambda関数追加
  - 🔍 正規表現ベースの攻撃検知
  - 🚨 疑わしいUser-Agentフィルタリング

- **v4.0.0** (2025-09-07)
  - Lambda Python runtime を3.13に更新
  - Input Variables化によるランタイム設定の柔軟化
  - セキュリティ設定の強化

- **v3.1.0** (2025-09-06)
  - CloudFormationサポート追加
  - Microsoft Teams通知機能追加
  - ドキュメント全面更新

- **v3.0.0** (2025-09-05)
  - プロジェクト構成整理
  - テスト・デプロイスクリプト追加
  - Makefile追加

- **v2.0.0** (2025-09-04)
  - WhiteList/BlackList機能追加
  - 段階的監視機能追加
  - 詳細アラート機能追加

- **v1.0.0** (2025-09-03)
  - 基本的なfail2ban機能を実装

## サポート

- **GitHub Issues**: https://github.com/HimekoYuri/aws-wafv2-fail2ban/issues
- **Documentation**: プロジェクト内のREADME.mdファイル
- **Examples**: `terraform.tfvars.example`, `parameters.json`

---

**🚀 Quick Start**: `cd terraform && cp terraform.tfvars.example terraform.tfvars && make init && make plan`