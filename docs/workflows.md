# GitHub Actions ワークフロー

このリポジトリでは、Terraform の Plan / Apply を自動化するための GitHub Actions ワークフローを提供しています。

## ワークフロー一覧

| ワークフロー | トリガー | 説明 |
|-------------|---------|------|
| `tf_plan.yml` | Pull Request | 変更された環境に対して `terraform plan` を実行 |
| `tf_apply.yml` | main ブランチへの push | 変更された環境に対して `terraform apply` を実行 |
| `tf_drift_detection.yml` | スケジュール (平日 9:00, 12:00, 15:00, 17:00 JST) | インフラのドリフト検出 |
| `tf_reviewdog.yml` | Pull Request | コード品質チェック (lint, validate, security scan) |

---

## Terraform Plan (`tf_plan.yml`)

Pull Request が作成・更新されると自動的に実行されます。

### 動作フロー

1. **Bot 判定**: PR の作成者が Bot (dependabot, renovate) かどうかを判定
2. **Plan 実行**: 変更されたディレクトリに対して `terraform plan` を実行
3. **結果コメント**: Plan 結果を PR にコメントとして投稿
4. **Bot PR の自動マージ**: Bot による PR で差分がない場合、自動的に承認・マージ

### 特徴

- **並列実行**: 複数の環境が変更された場合、並列で Plan を実行
- **キャンセル機能**: 新しいコミットがプッシュされると、実行中の Plan をキャンセル
- **tfcmt**: Plan 結果を見やすい形式で PR にコメント

```
Pull Request
    │
    ▼
┌─────────────┐    ┌─────────────┐
│ check_bot   │───▶│ plan_human  │ (一般ユーザー)
└─────────────┘    └─────────────┘
    │
    ▼
┌─────────────┐    ┌─────────────────────┐
│ plan_bot    │───▶│ merge_pull_request  │ (Bot: 自動マージ)
└─────────────┘    └─────────────────────┘
```

---

## Terraform Apply (`tf_apply.yml`)

main ブランチにマージされると自動的に実行されます。

### 動作フロー

1. **メンテナンスモード確認**: `TF_MAINTENANCE` 変数が `true` の場合はスキップ
2. **変更ディレクトリの特定**: main ブランチで変更されたディレクトリを検出
3. **Apply 実行**: 各ディレクトリに対して `terraform apply -auto-approve` を実行
4. **Slack 通知**: 結果を Slack に通知（メンテナンスモード時も通知）

### 特徴

- **並列実行制御**: `max_parallel` 設定で同時実行数を制限
- **環境ごとの排他制御**: 同じ環境に対する Apply は直列実行
- **メンテナンスモード**: `vars.TF_MAINTENANCE=true` で Apply を一時停止可能

```
main ブランチへの push
    │
    ▼
┌──────────────────────┐
│ check-maintenance    │
└──────────────────────┘
    │
    ├─▶ メンテナンス中 ─▶ Slack 通知
    │
    ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│  envs   │───▶│  dirs   │───▶│  apply  │ (並列実行)
└─────────┘    └─────────┘    └─────────┘
```

---

## ドリフト検出 (`tf_drift_detection.yml`)

スケジュール実行により、インフラの意図しない変更（ドリフト）を検出します。

### 実行スケジュール

- **平日のみ**: 月曜日〜金曜日
- **実行時刻 (JST)**: 9:00, 12:00, 15:00, 17:00

### 動作フロー

1. **全環境の Plan 実行**: `terraform plan -detailed-exitcode` を全ディレクトリに対して実行
2. **ドリフト検出時**: 自動的に Pull Request を作成
3. **ドリフトなしの場合**: 既存の PR があればクローズ

### 特徴

- **手動実行**: `workflow_dispatch` により手動でも実行可能
- **PR による通知**: ドリフトが検出されると PR が作成され、レビュワーに通知
- **自動クローズ**: ドリフトが解消されると PR は自動的にクローズ

```
スケジュール実行 (平日 4 回)
    │
    ▼
┌──────────┐    ┌──────────┐
│ prepare  │───▶│   plan   │ (全環境)
└──────────┘    └──────────┘
                     │
    ┌────────────────┴────────────────┐
    ▼                                 ▼
ドリフトあり                      ドリフトなし
    │                                 │
    ▼                                 ▼
PR 作成                           既存 PR をクローズ
```

---

## コード品質チェック (`tf_reviewdog.yml`)

Pull Request に対して、複数の Lint ツールを実行します。

### チェック項目

| ジョブ | ツール | チェック内容 |
|--------|--------|-------------|
| `fmt` | `terraform fmt` | Terraform コードのフォーマット |
| `validate` | `terraform validate` | Terraform 構文の検証 |
| `tflint` | TFLint | Terraform のベストプラクティス違反 |
| `trivy` | Trivy | セキュリティ脆弱性スキャン |
| `shellcheck` | ShellCheck | シェルスクリプトの品質チェック |
| `actionlint` | actionlint | GitHub Actions ワークフローの検証 |
| `misspell` | misspell | スペルミス検出 |

### 特徴

- **PR コメント**: 問題が検出されると、該当行に直接コメント
- **キャッシュ**: TFLint プラグインをキャッシュして高速化
- **並列実行**: 各 Lint ジョブは独立して並列実行

```
Pull Request
    │
    ▼
┌─────────────────────────────────────────────────────┐
│                    並列実行                          │
│  ┌─────┐ ┌──────────┐ ┌────────┐ ┌───────┐         │
│  │ fmt │ │ validate │ │ tflint │ │ trivy │ ...     │
│  └─────┘ └──────────┘ └────────┘ └───────┘         │
└─────────────────────────────────────────────────────┘
    │
    ▼
reviewdog_succeeded (全チェック完了)
```

---

## 再利用可能ワークフロー

メインのワークフローは、以下の再利用可能ワークフロー (`_*.yml`) を呼び出しています。

| ワークフロー | 説明 |
|-------------|------|
| `_tf_check_bot.yml` | PR 作成者が Bot かどうかを判定 |
| `_tf_dirs.yml` | 変更されたディレクトリを検出 |
| `_tf_envs.yml` | 環境設定を読み込み |
| `_tf_plan.yml` | Terraform Plan の実行ロジック |
| `_tf_prepare.yml` | Plan 実行前の準備処理 |
| `_tf_terraform.yml` | Terraform コマンドの実行 |
| `_tf_create_status.yml` | GitHub ステータスの更新 |
| `_tf_slack_notification.yml` | Slack への通知 |

---

## 必要な設定

### Repository Variables

| 変数名 | 説明 |
|--------|------|
| `RUNNER_TERRAFORM` | Terraform 実行用のランナー名 |
| `TF_MAINTENANCE` | メンテナンスモード (`true` / `false`) |

### Repository Secrets

| シークレット名 | 説明 |
|---------------|------|
| `BOT_APP_PRIVATE_KEY` | GitHub App の秘密鍵 |
| `SLACK_WEBHOOK_URL` | Slack 通知用の Webhook URL |

### Environment Variables (`.github/tf/config/.env`)

| 変数名 | 説明 |
|--------|------|
| `BOT_APP_ID` | GitHub App の ID |
| `GIT_USER_EMAIL` | コミット用のメールアドレス |
| `GIT_USER_NAME` | コミット用のユーザー名 |
| `SLACK_CHANNEL_ID` | Slack チャンネル ID |
