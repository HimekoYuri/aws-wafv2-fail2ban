# AWS WAFv2 Advanced Fail2ban - 機能ガイド (2026年最新版)

## 新機能概要

### 2026年4月更新

1. **OWASP Top 10:2026対応**
   - A01: Broken Access Control (SSRF統合)
   - A03: Software Supply Chain Failures
   - A05: Injection (SQLi, NoSQLi, GraphQL, JNDI)
   - A10: Mishandling of Exceptional Conditions

2. **AI駆動攻撃対策**
   - AI自動スキャナ・クローラー検知
   - LLMエージェント・GPTプラグイン検知
   - 自動エクスプロイトツール検知

3. **モダン攻撃パターン**
   - SSRF (クラウドメタデータエンドポイント)
   - NoSQLインジェクション / プロトタイプ汚染
   - GraphQLイントロスペクション乱用
   - Log4Shell / JNDI系攻撃 (継続的脅威)
   - エンコーディング回避攻撃 (null byte, double encoding)
   - HTTP Flood / Slowloris (大量ヘッダー検知)

4. **インフラ最新化**
   - Terraform >= 1.6 / AWS Provider ~> 5.80
   - Lambda Python 3.13 + 型ヒント
   - Teams Adaptive Card形式
   - IP TTL自動期限切れ
   - rate_based_statement構文修正

## セキュリティルール詳細

### 従来型攻撃パターン (Rule 3: AttackPatternRule)
- SQLi: UNION-based, stacked queries, blind injection
- XSS: DOM-based, reflected, stored, SVG-based
- ディレクトリトラバーサル: パスインジェクション + エンコーディング回避
- コマンドインジェクション: shell meta characters
- サーバサイドコード実行: 危険な拡張子 (php, asp, jsp, cgi等)

### モダン攻撃パターン (Rule 4: ModernAttackPatternRule)
- SSRF: 169.254.169.254, metadata.google, 100.100.100.200
- NoSQLi: __proto__, $gt/$lt/$ne/$regex/$where
- GraphQL: __schema, __type, introspectionQuery
- Log4Shell: ${jndi:}, ${lower:}, ${env:}
- エンコーディング回避: %00, %0a, double encoding

### 疑わしいUser-Agent (Rule 5: SuspiciousUserAgentRule)
- セキュリティスキャナ: nikto, sqlmap, nmap, nuclei, httpx
- AI自動化ツール: ai-scanner, gpt-crawler, llm-agent
- スクレイパー: scrapy, selenium, puppeteer, playwright, crawl4ai
- 短い/空のUser-Agent: 5文字以下

### 大量ヘッダー検知 (Rule 10: OversizedHeaderRule)
- 8KB超のHTTPヘッダーをブロック
- HTTP Flood / Slowloris攻撃対策

## 段階的制裁システム

| Stage | 閾値 | アクション | 結果 |
|-------|------|-----------|------|
| 1 | count_threshold | Count | アラート発生 |
| 2 | rate_limit_requests | Block | 再犯者リスト追加 |
| 3 | rate_limit_requests × 2 | Block | 重度犯罪者リスト追加 |
| 4 | rate_limit_requests × 3 | Block | 最重度制裁 |

## IP自動管理

### TTL期限切れ
- `ip_ttl_hours` で自動削除期間を設定 (デフォルト: 24時間)
- 0に設定すると無期限
- CloudWatch Logsのタイムスタンプベースで判定

### OptimisticLockリトライ
- WAFv2のLockToken競合時に最大3回リトライ
- 並行更新時の安全性を確保
