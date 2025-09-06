# AWS WAFv2 Advanced Fail2ban Integration

AWS WAFv2を使用した高度なfail2ban機能とIP管理システム

## 概要

このプロジェクトは、AWS WAFv2を使用してfail2banのような機能を実現し、CloudFront + S3で構成されたWebサイトのセキュリティを強化するためのTerraformソリューションです。WhiteList/BlackList機能、段階的な監視・ブロック機能、詳細なアラート機能を提供します。

## プロジェクト構成

```
aws-wafv2-fail2ban/
├── terraform/           # Terraformファイル
│   ├── *.tf            # Terraform設定ファイル
│   ├── lambda/         # Lambda関数
│   └── terraform.tfvars.example
├── scripts/            # 運用スクリプト
│   ├── test.sh        # テストスクリプト
│   └── deploy.sh      # デプロイスクリプト
├── Makefile           # Make操作定義
└── README.md          # このファイル
```

## 主要機能

### 🛡️ 4段階のセキュリティルール

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

### 🎯 対象パス設定

- `/website`配下の全てのURI（サブパス含む）に対応
- 例: `/website/`, `/website/download`, `/website/api/v1` など

## クイックスタート

### 1. 前提条件

- Terraform >= 1.0
- AWS CLI設定済み（AWS SSO対応）
- 適切なIAM権限
- 既存のCloudFront Distribution

### 2. 設定ファイルの作成

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集して環境に合わせて設定
```

## デプロイ方法

### Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集
make init
make plan
make apply
```

### CloudFormation

```bash
cd cloudformation
# parameters.jsonを編集
./deploy.sh
```

### スクリプトを使用した操作

```bash
# テスト実行
./scripts/test.sh

# デプロイ実行（Terraform）
./scripts/deploy.sh
```

## 設定パラメータ

| パラメータ | デフォルト値 | 説明 |
|-----------|-------------|------|
| `count_threshold` | 50 | Count閾値（アラート発生） |
| `rate_limit_requests` | 100 | Block閾値（ブロック実行） |
| `block_duration_seconds` | 3600 | ブロック継続時間（秒） |
| `target_path` | "/website" | 監視対象のパス |
| `whitelist_ips` | [] | ホワイトリストIP一覧 |
| `blacklist_ips` | [] | ブラックリストIP一覧 |
| `notification_email` | "" | SNS通知用メールアドレス |
| `slack_webhook_url` | "" | Slack Webhook URL |
| `slack_channel` | "aws_system_notify" | Slackチャンネル名 |

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
    SNS → Email & Slack通知
```

## 監視とアラート

### CloudWatch Logs
- ロググループ: `/aws/wafv2/fail2ban`
- 保持期間: 30日
- 機密情報除外済み

### CloudWatch Alarms

1. **Count Threshold Alarm** (`waf-count-threshold-exceeded`)
2. **IP Blocked Alarm** (`waf-ip-blocked-alert`)
3. **IP Unblocked Alarm** (`waf-ip-unblocked-alert`)

### 通知システム
- **SNS Topic**: `waf-fail2ban-notifications`
- **Email通知**: 設定したメールアドレスに配信
- **Slack通知**: 指定チャンネルに配信

## セキュリティ注意事項

⚠️ **重要**: このバージョンではAWS Managed Rulesを無効化しています
- 脆弱性リスクが高くなる可能性があります
- 本番環境での使用は慎重に検討してください
- 定期的なセキュリティ監査を実施してください

## トラブルシューティング

### よくある問題

1. **CloudFrontとの関連付けエラー**
   - Web ACLのスコープが`CLOUDFRONT`であることを確認
   - us-east-1リージョンでの作成を確認

2. **通知が届かない**
   - SNS Topic Policyの設定を確認
   - Slack Webhook URLの有効性を確認

3. **テストが失敗する**
   - `./scripts/test.sh`でエラー詳細を確認
   - 必要な依存関係がインストールされているか確認

## ライセンス

MIT License

## 貢献

プルリクエストやイシューの報告を歓迎します。セキュリティに関する問題は、直接メンテナーにご連絡ください。

## 更新履歴

- v3.0.0: プロジェクト構成整理、テスト・デプロイスクリプト追加、Makefile追加
- v2.0.0: WhiteList/BlackList機能、段階的監視機能、詳細アラート機能を追加
- v1.0.0: 基本的なfail2ban機能を実装