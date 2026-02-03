# tsh を使った Kubernetes アクセス（コアなエンドユーザ向け）

Teleport の `tsh` / `tctl` コマンドを直接利用して、Kubernetes クラスタへのアクセスや本番環境への一時的なアクセス申請（Access Request）を行うための詳細手順です。

## 基本ログイン

```bash
tsh logout
tsh login --proxy=teleport.example.com:443 --auth=github
```

## Kubernetes クラスタへのログイン

```bash
# 利用可能なクラスタを確認
tsh kube ls

# クラスタにログイン
tsh kube login project-b-prod-default  # 本番環境
tsh kube login project-b-staging-default  # ステージング環境

# 動作確認
kubectl get pods
```

## Access Request（本番環境へのアクセス申請）

`standard` チームのユーザーは `request_prd` ロールを持っており、本番環境（`prd`）へのアクセスをリクエストできます。

### リクエスター（申請者）

申請者向けには、対話的に Access Request を作成するスクリプトがあります。

```bash
# インタラクティブにリクエスト
./scripts/request-prd.sh
```

スクリプトを使わず、手動で実行する場合は以下のようにします。

```bash
tsh login --proxy=teleport.example.com:443 --auth=github

tsh request create \
  --roles=prd \
  --reviewers=<reviewer_username> \
  --reason="本番環境でのデバッグ作業"

# リクエスト状況の確認
tsh request ls

# 承認後、リクエストIDでログイン
tsh login --proxy=teleport.example.com:443 --request-id=<request-id>

# 本番クラスタにアクセス
tsh kube login project-b-prod-default
```

### レビュワー（承認者）

レビュワーは、Auth Service 上で `tctl` を実行してリクエストを承認 / 拒否します。

```bash
# リクエスト一覧
tctl requests ls

# 承認
tctl request approve <request-id> --reason="承認しました"

# 拒否
tctl request deny <request-id> --reason="理由を記載"
```

レビュワー向けにも、インタラクティブに承認操作を行うスクリプトがあります（fzf 対応）。

```bash
./scripts/approve-request.sh
```

## kubectl-exec.sh との関係

`scripts/kubectl-exec.sh` は、Teleport に `tsh` でログインした状態を前提として、
Kubernetes クラスタの選択（`tsh kube login`）から Pod / コンテナの選択、`kubectl exec` によるシェルログインまでを一括で行うためのラッパースクリプトです。

- `tsh` / `tctl` による認証・リクエストフローの理解: 本ドキュメント（`docs/tsh.md`）
- 具体的な Pod / コンテナへの接続操作: `scripts/kubectl-exec.sh`
