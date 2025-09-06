# CloudFormation Deployment

AWS WAFv2 Fail2ban システムのCloudFormationテンプレート

## ファイル構成

```
cloudformation/
├── waf-fail2ban.yaml    # CloudFormationテンプレート
├── parameters.json      # パラメータファイル
├── deploy.sh           # デプロイスクリプト
└── README.md           # このファイル
```

## クイックスタート

### 1. パラメータの設定

`parameters.json`を編集して環境に合わせて設定：

```json
[
  {
    "ParameterKey": "NotificationEmail",
    "ParameterValue": "your-email@example.com"
  },
  {
    "ParameterKey": "SlackWebhookUrl",
    "ParameterValue": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
  }
]
```

### 2. デプロイ実行

```bash
# デプロイスクリプトを使用
./deploy.sh

# または直接AWS CLIを使用
aws cloudformation deploy \
  --template-file waf-fail2ban.yaml \
  --stack-name aws-wafv2-fail2ban \
  --parameter-overrides file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM
```

## パラメータ

| パラメータ | デフォルト値 | 説明 |
|-----------|-------------|------|
| `DomainName` | `download.lovelive-presents.com` | ドメイン名 |
| `CountThreshold` | `50` | Count閾値（アラート発生） |
| `RateLimitRequests` | `100` | Block閾値（ブロック実行） |
| `TargetPath` | `/website` | 監視対象のパス |
| `WhitelistIPs` | `` | ホワイトリストIP（カンマ区切り） |
| `BlacklistIPs` | `` | ブラックリストIP（カンマ区切り） |
| `NotificationEmail` | `` | SNS通知用メールアドレス |
| `SlackWebhookUrl` | `` | Slack Webhook URL |
| `SlackChannel` | `aws_system_notify` | Slackチャンネル名 |

## 作成されるリソース

### WAFv2
- IP Set (Whitelist/Blacklist)
- Web ACL (4つのルール)
- Logging Configuration

### 監視・通知
- CloudWatch Log Group
- CloudWatch Alarms (3つ)
- SNS Topic
- Lambda Function (Slack通知用)

### IAM
- Lambda実行ロール
- 必要な権限ポリシー

## 出力値

- `WebACLArn`: Web ACLのARN
- `WebACLId`: Web ACLのID
- `SNSTopicArn`: SNS TopicのARN

## CloudFrontとの関連付け

デプロイ後、CloudFrontディストリビューションに手動でWeb ACLを関連付けてください：

```bash
aws cloudfront update-distribution \
  --id YOUR_DISTRIBUTION_ID \
  --distribution-config file://distribution-config.json
```

## 削除

```bash
aws cloudformation delete-stack --stack-name aws-wafv2-fail2ban
```

## トラブルシューティング

### よくある問題

1. **IAM権限エラー**
   - `CAPABILITY_NAMED_IAM`が必要です
   - 適切なIAM権限があることを確認

2. **リージョンエラー**
   - CloudFront用WAFはus-east-1で作成する必要があります

3. **パラメータエラー**
   - parameters.jsonの形式を確認
   - 必須パラメータが設定されているか確認
