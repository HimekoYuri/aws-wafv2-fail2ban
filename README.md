# AWS WAFv2 Advanced Fail2ban Integration

AWS WAFv2を使用した高度なfail2ban機能とIP管理システム

## 概要

このプロジェクトは、AWS WAFv2を使用してfail2banのような機能を実現し、CloudFront + S3で構成されたWebサイトのセキュリティを強化するためのTerraformソリューションです。WhiteList/BlackList機能、段階的な監視・ブロック機能、詳細なアラート機能を提供します。

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

### 🎯 対象パス設定

- `/website`配下の全てのURI（サブパス含む）に対応
- 例: `/website/`, `/website/download`, `/website/api/v1` など

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
```

## セキュリティ設定

### IP管理
- **WhiteList**: 信頼できるIPアドレス（社内ネットワーク等）
- **BlackList**: 既知の悪意のあるIPアドレス
- **動的ブロック**: レート制限による自動ブロック

### 閾値設定
- **Count閾値**: 50リクエスト/5分（アラート用）
- **Block閾値**: 100リクエスト/5分（ブロック用）
- **ブロック時間**: 1時間（3600秒）

### プライバシー保護
- **機密情報の除外**: Authorization、Cookieヘッダーをログから除外
- **データ暗号化**: CloudWatch Logsでの保存時暗号化

## 前提条件

- Terraform >= 1.0
- AWS CLI設定済み（AWS SSO対応）
- 適切なIAM権限
- 既存のCloudFront Distribution

## セットアップ手順

### 1. リポジトリのクローン
```bash
git clone <repository-url>
cd aws-wafv2-fail2ban
```

### 2. 設定ファイルの作成
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. 設定値の編集
`terraform.tfvars`ファイルを編集して、環境に合わせて設定値を調整してください：

```hcl
# 必須設定
domain_name = "your-domain.com"
cloudfront_distribution_id = "E1234567890ABC"

# 閾値設定
count_threshold = 50       # Count閾値（アラート用）
rate_limit_requests = 100  # Block閾値（ブロック用）
block_duration_seconds = 3600  # ブロック時間（秒）
target_path = "/website"   # 監視対象パス

# IP管理
whitelist_ips = [
  "192.168.1.0/24",    # 社内ネットワーク
  "10.0.0.1/32",       # 管理者IP
]

blacklist_ips = [
  "203.0.113.0/24",    # 既知の攻撃元
  "198.51.100.1/32",   # ブロック対象IP
]
```

### 4. Terraformの初期化と実行
```bash
# 初期化
terraform init

# プランの確認
terraform plan

# 適用
terraform apply
```

### 5. CloudFrontとの関連付け
WAF Web ACLが作成された後、CloudFrontディストリビューションに手動で関連付けてください：

1. AWS Console → CloudFront
2. 対象のディストリビューション選択
3. Security タブ → AWS WAF web ACL
4. 作成されたWeb ACL（`fail2ban-waf-acl`）を選択

## 設定パラメータ

| パラメータ | デフォルト値 | 説明 |
|-----------|-------------|------|
| `count_threshold` | 50 | Count閾値（アラート発生） |
| `rate_limit_requests` | 100 | Block閾値（ブロック実行） |
| `block_duration_seconds` | 3600 | ブロック継続時間（秒） |
| `target_path` | "/website" | 監視対象のパス |
| `whitelist_ips` | [] | ホワイトリストIP一覧 |
| `blacklist_ips` | [] | ブラックリストIP一覧 |
| `aws_region` | "us-east-1" | AWSリージョン |
| `aws_profile` | "YukiSunaoka" | AWSプロファイル |

## 監視とアラート

### CloudWatch Logs
- ロググループ: `/aws/wafv2/fail2ban`
- 保持期間: 30日
- 機密情報除外済み

### CloudWatch Alarms

1. **Count Threshold Alarm** (`waf-count-threshold-exceeded`)
   - Count値が閾値を超えた際にアラート
   - 潜在的な攻撃の早期検知

2. **IP Blocked Alarm** (`waf-ip-blocked-alert`)
   - IPがブロックされた際にアラート
   - ブロック実行の通知

3. **IP Unblocked Alarm** (`waf-ip-unblocked-alert`)
   - IPブロックが解除された際にアラート
   - ブロック解除の通知

### メトリクス
- `AllowedRequests`: 許可されたリクエスト数
- `BlockedRequests`: ブロックされたリクエスト数
- ルール別の詳細メトリクス

## IP管理

### WhiteListの管理
```bash
# terraform.tfvarsでwhitelist_ipsを更新
whitelist_ips = [
  "192.168.1.0/24",
  "10.0.0.1/32",
]

# 適用
terraform apply
```

### BlackListの管理
```bash
# terraform.tfvarsでblacklist_ipsを更新
blacklist_ips = [
  "203.0.113.0/24",
  "198.51.100.1/32",
]

# 適用
terraform apply
```

## セキュリティベストプラクティス

1. **最小権限の原則**: 必要最小限のIAM権限のみ付与
2. **定期的なIP管理**: WhiteList/BlackListの定期見直し
3. **閾値の調整**: トラフィックパターンに応じた閾値調整
4. **アラート監視**: CloudWatchアラームの定期確認
5. **ログ分析**: 定期的なアクセスログの分析

## トラブルシューティング

### よくある問題

1. **CloudFrontとの関連付けエラー**
   - Web ACLのスコープが`CLOUDFRONT`であることを確認
   - us-east-1リージョンでの作成を確認

2. **IP Setが空の場合のエラー**
   - 空のIP Setでもエラーは発生しません
   - 必要に応じて後から追加可能

3. **アラートが発生しない**
   - CloudWatchメトリクスの設定を確認
   - 閾値設定の見直し

4. **ログが出力されない**
   - WAF Logging Configurationの設定を確認
   - CloudWatch Logsの権限を確認

## パフォーマンス最適化

- CloudWatch Logsの保持期間調整
- 不要なメトリクスの無効化
- アラームの閾値最適化
- IP Setサイズの管理

## コスト最適化

- CloudWatch Logsの保持期間: 30日
- メトリクス収集の最適化
- アラーム数の管理
- 不要なログの除外

## セキュリティ注意事項

⚠️ **重要**: このバージョンではAWS Managed Rulesを無効化しています
- 脆弱性リスクが高くなる可能性があります
- 本番環境での使用は慎重に検討してください
- 定期的なセキュリティ監査を実施してください

## ライセンス

MIT License

## 貢献

プルリクエストやイシューの報告を歓迎します。セキュリティに関する問題は、直接メンテナーにご連絡ください。

## 更新履歴

- v2.0.0: WhiteList/BlackList機能、段階的監視機能、詳細アラート機能を追加
- v1.0.0: 基本的なfail2ban機能を実装