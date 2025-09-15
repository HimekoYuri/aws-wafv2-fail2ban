# AWS WAFv2 Advanced Fail2ban - 新機能ガイド

## 🚀 **新機能概要**

このブランチでは、本家fail2banに近い高度な機能を実装しました！

### ✨ **実装済み新機能**

1. **🔍 ログパターンマッチング機能**
   - 正規表現ベースの攻撃パターン検知
   - SQLインジェクション、XSS、ディレクトリトラバーサル対応
   - 疑わしいUser-Agent検知

2. **🎯 段階的制裁システム**
   - Stage 1: 警告レベル（Count）
   - Stage 2: 軽度制限（Block）
   - Stage 3: 再犯者制限（重度Block）
   - Stage 4: 重度犯罪者制限（最重度Block）

3. **🤖 自動IP管理**
   - Lambda関数による動的IP Set更新
   - 再犯者の自動エスカレーション
   - CloudWatch Logsとの連携

## 📁 **新しいファイル構成**

```
terraform/
├── pattern_sets.tf          # 正規表現パターン定義
├── ip_sets.tf              # IP Set定義（分離）
├── advanced_rules.tf       # 高度なWAFルール
├── lambda_functions.tf     # Lambda関数設定
├── advanced_alarms.tf      # 高度なアラーム設定
└── lambda/
    └── ip_manager.py       # IP管理Lambda関数
```

## 🛡️ **セキュリティルール詳細**

### **攻撃パターン検知**
- **SQLインジェクション**: `union|select|insert|update|delete|drop|create|alter|exec|execute`
- **XSS攻撃**: `<script|javascript:|onload=|onerror=|onclick=`
- **ディレクトリトラバーサル**: `\\.\\.[/\\\\]|\\.\\%2f|\\.\\%5c`
- **悪意のあるファイル**: `\\.(php|asp|aspx|jsp|cgi|pl)`
- **コマンドインジェクション**: `;|\\||&|`|\\$\\(|\\${`

### **疑わしいUser-Agent**
- **自動化ツール**: `bot|crawler|spider|scraper|scanner|curl|wget|python|perl`
- **空のUser-Agent**: 完全に空白
- **短すぎるUser-Agent**: 10文字以下

## 🎯 **段階的制裁システム**

### **Stage 1: 警告レベル**
- **閾値**: `count_threshold` (デフォルト: 50req/5min)
- **アクション**: Count（ログのみ）
- **目的**: 監視・アラート発生

### **Stage 2: 軽度制限**
- **閾値**: `rate_limit_requests` (デフォルト: 100req/5min)
- **アクション**: Block
- **結果**: 再犯者リストに自動追加

### **Stage 3: 再犯者制限**
- **対象**: 再犯者IP Set内のIP
- **閾値**: `rate_limit_requests * 2` (デフォルト: 200req/5min)
- **アクション**: Block
- **結果**: 重度犯罪者リストに自動追加

### **Stage 4: 重度犯罪者制限**
- **対象**: 重度犯罪者IP Set内のIP
- **閾値**: `rate_limit_requests * 3` (デフォルト: 300req/5min)
- **アクション**: Block
- **結果**: 最重度制裁

## 🤖 **Lambda関数機能**

### **IP Manager Lambda**
- **トリガー**: CloudWatch Alarm → SNS → Lambda
- **機能**:
  - Stage2でブロックされたIPを再犯者リストに追加
  - Stage3でブロックされたIPを重度犯罪者リストに追加
  - CloudWatch Logsからブロック対象IPを自動抽出

### **処理フロー**
```
WAF Rule Block → CloudWatch Alarm → SNS → Lambda → IP Set Update
```

## 📊 **新しいCloudWatchアラーム**

1. **waf-attack-pattern-detected**: 攻撃パターン検知
2. **waf-suspicious-user-agent-detected**: 疑わしいUser-Agent検知
3. **waf-stage1-warning-threshold**: Stage1警告レベル
4. **waf-stage2-light-block**: Stage2軽度制限
5. **waf-stage3-repeat-offender-block**: Stage3再犯者制限
6. **waf-stage4-heavy-offender-block**: Stage4重度犯罪者制限

## 🔧 **設定方法**

### **新しい変数**
```hcl
# terraform.tfvars に追加
enable_advanced_rules        = true
enable_user_agent_filtering  = true
```

### **デプロイ手順**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 📈 **監視・運用**

### **IP Set確認**
```bash
# 再犯者リスト確認
aws wafv2 get-ip-set --scope CLOUDFRONT --id <repeat-offenders-id> --name fail2ban-repeat-offenders

# 重度犯罪者リスト確認
aws wafv2 get-ip-set --scope CLOUDFRONT --id <heavy-offenders-id> --name fail2ban-heavy-offenders
```

### **Lambda関数ログ確認**
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/fail2ban-ip-manager"
```

## ⚠️ **注意事項**

1. **コスト**: WAFルール数増加により料金が上昇します
2. **性能**: 正規表現マッチングは処理負荷が高くなる可能性があります
3. **IP Set制限**: AWS WAFv2のIP Set制限（10,000エントリ）にご注意ください
4. **Lambda実行**: IP Set更新には数秒の遅延があります

## 🔄 **今後の拡張予定**

- [ ] DynamoDBによる履歴管理
- [ ] 時間ベースの自動IP解除
- [ ] 地理的ブロック機能
- [ ] 機械学習ベースの異常検知
- [ ] 詳細な統計レポート機能

---

**🎉 これで本家fail2banに近い高度な機能が利用できるようになりました！**