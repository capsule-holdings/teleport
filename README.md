# Teleport Infrastructure

GKE クラスタ上に [Teleport](https://goteleport.com/) をデプロイし、複数の Kubernetes クラスタへのセキュアなアクセスを管理するための Terraform コードとスクリプト類をまとめたリポジトリです。

## 概要

このリポジトリは、以下の機能を提供します：

- **Teleport サーバーのデプロイ**: GKE 上に Teleport Auth/Proxy サーバーをデプロイ
- **Kubernetes Agent のデプロイ**: 各環境の Kubernetes クラスタに Teleport Agent をデプロイし、中央管理された認証でアクセス
- **GitHub SSO 連携**: GitHub Organization のチームベースでロールを割り当て
- **RBAC (Role-Based Access Control)**: 本番環境 (prd) / ステージング環境 (stg) ごとのアクセス制御
- **Access Request**: 本番環境への一時的なアクセス申請・承認ワークフロー

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                      teleport-central (GKE)                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Teleport Cluster (Auth + Proxy)                        │   │
│  │  - GitHub SSO 認証                                       │   │
│  │  - ロール管理 (root, prd, stg, request_prd)             │   │
│  │  - Access Request ワークフロー                           │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ project-a-prod  │  │ project-a-stg   │  │ project-b-*     │
│ (Kube Agent)    │  │ (Kube Agent)    │  │ (Kube Agent)    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 技術スタック

- **IaC**: Terraform
- **クラウド**: Google Cloud Platform (GKE, VPC, Cloud NAT, Secret Manager)
- **認証**: Teleport + GitHub SSO
- **CI/CD**: GitHub Actions (Plan/Apply ワークフロー)
- **証明書管理**: cert-manager + Let's Encrypt
- **Kubernetes**: Helm (Teleport Helm Chart)

## ディレクトリ構成

```
.
├── envs/                          # 環境ごとの Terraform 設定
│   ├── teleport-central/          # Teleport サーバー本体 (GKE + Helm)
│   │   ├── modules/
│   │   │   ├── gke/               # GKE クラスタ構築
│   │   │   ├── helm/              # Teleport Helm デプロイ
│   │   │   └── teleport/          # Teleport リソース (ロール, SSO)
│   │   └── *.tf
│   ├── project-a-prod/            # Project A 本番環境の Kube Agent
│   ├── project-a-staging/         # Project A ステージング環境の Kube Agent
│   ├── project-b-prod/            # Project B 本番環境の Kube Agent
│   └── project-b-staging/         # Project B ステージング環境の Kube Agent
├── modules/                       # 共有 Terraform モジュール
│   ├── kube-agent/                # Kubernetes Agent モジュール
│   └── db-agent/                  # Database Agent モジュール
├── scripts/                       # 運用スクリプト
│   ├── kubectl-exec.sh            # Pod へのインタラクティブ接続
│   ├── request-prd.sh             # 本番アクセス申請
│   ├── approve-request.sh         # アクセス申請の承認/拒否
│   └── login-prd.sh               # 承認後の本番ログイン
├── docs/                          # ドキュメント
│   ├── end-users.md               # エンドユーザ向けガイド
│   ├── tsh.md                     # tsh コマンド詳細
│   ├── cluster-admin.md           # 管理者向けガイド
│   └── workflows.md               # CI/CD ワークフロー
└── .github/
    └── workflows/                 # CI/CD ワークフロー
        ├── tf_plan.yml            # Terraform Plan
        └── tf_apply.yml           # Terraform Apply
```

## セットアップ

### 前提条件

- Terraform >= 1.0
- gcloud CLI (認証済み)
- kubectl
- [tsh](https://goteleport.com/docs/connect-your-client/tsh/) (Teleport CLI)

### Teleport サーバーのデプロイ

```bash
cd envs/teleport-central
terraform init
terraform plan
terraform apply
```

### Kubernetes Agent のデプロイ

```bash
cd envs/project-b-prod
terraform init
terraform plan
terraform apply
```

## ドキュメント構成

このリポジトリの利用者を、以下の 3 つのペルソナに分けてドキュメントを用意しています。

### 1. エンドユーザ向け: シェルスクリプトの使い方

Teleport 経由で Kubernetes にアクセスしたり、本番環境への一時的なアクセス申請を行いたい一般的な利用者向けです。

- Pod へ `kubectl exec` で入る: `scripts/kubectl-exec.sh`
- 本番環境への Access Request を送る: `scripts/request-prd.sh`
- 本番環境への Access Request を承認/拒否する（レビュワー向け）: `scripts/approve-request.sh`

具体的な使い方は次を参照してください。

- [docs/end-users.md](docs/end-users.md)

### 2. コアなエンドユーザ向け: tsh コマンドの使い方

`tsh` / `tctl` コマンドを直接叩いて、Teleport の機能を細かく制御したい利用者向けです。

- `tsh login` によるログイン
- `tsh kube ls` / `tsh kube login` による Kubernetes クラスタへのログイン
- Access Request（本番環境への一時的なアクセス申請）の手動操作

詳しくは次を参照してください。

- [docs/tsh.md](docs/tsh.md)

### 3. クラスタ管理者向け: 運用手順

Terraform Provider 用ユーザーの鍵発行など、Teleport Auth Service / Kubernetes クラスタの運用に関わる管理者向けの手順です。

- Terraform Provider 用ユーザーの作成と鍵のコピー

詳しくは次を参照してください。

- [docs/cluster-admin.md](docs/cluster-admin.md)

### 4. CI/CD: GitHub Actions ワークフロー

Terraform の Plan / Apply を自動化する GitHub Actions ワークフローの詳細です。

- Terraform Plan (PR 作成時)
- Terraform Apply (main マージ時)
- ドリフト検出 (スケジュール実行)
- コード品質チェック (tflint, trivy, shellcheck など)

詳しくは次を参照してください。

- [docs/workflows.md](docs/workflows.md)

## Access Request ワークフロー

本番環境へのアクセスは、以下のワークフローで管理されています：

1. **申請**: `standard` チームのユーザーが `request_prd` ロールを使って本番アクセスを申請
2. **承認**: `admin` または `root` チームのレビュワーが申請を承認/拒否
3. **アクセス**: 承認後、申請者は一時的に `prd` ロールを取得し、本番環境にアクセス可能

```bash
# 申請者
./scripts/request-prd.sh

# レビュワー
./scripts/approve-request.sh

# 承認後のログイン
./scripts/login-prd.sh <request-id>
```

## ロール設計

| ロール | 説明 | 対象チーム |
|--------|------|------------|
| `root` | 全リソースへのフルアクセス | root チーム |
| `prd` | 本番環境へのアクセス | admin チーム |
| `stg` | ステージング環境へのアクセス | admin, standard, lite チーム |
| `request_prd` | 本番アクセスの申請権限 | standard チーム |