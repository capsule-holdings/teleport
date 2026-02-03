# エンドユーザ向け: シェルスクリプトの使い方

Teleport 経由で Kubernetes にアクセスしたり、本番環境への一時的なアクセス申請を行うためのシェルスクリプトの使い方をまとめています。

## Pod に入ってデバッグする: kubectl-exec.sh

`scripts/kubectl-exec.sh` は、Teleport の認証から Kubernetes クラスタ・Pod・コンテナの選択までをインタラクティブに行い、`kubectl exec` でシェルに入るためのラッパースクリプトです。

基本的には、対話的なプロンプトに従ってクラスタや Pod / コンテナを選ぶだけで利用できます。

### 使い方

```bash
cd scripts

# 対話的にクラスタ / Pod / コンテナを選択
./kubectl-exec.sh

# GitHub ユーザー名を引数で指定
./kubectl-exec.sh -u your-github-username

# GitHub ユーザー名を環境変数で指定
GITHUB_USER=your-github-username ./kubectl-exec.sh
```

より詳細なオプション（アプリ種別の指定など）が必要な場合は、ヘルプを参照してください。

```bash
./kubectl-exec.sh -h
```

## 本番環境へのアクセス申請: request-prd.sh

`scripts/request-prd.sh` は、本番環境（`prd`）への一時的なアクセスを Teleport の Access Request 機能で申請するためのスクリプトです。

### 前提

- `standard` チームのユーザーであり、`request_prd` ロールが付与されていること。
- Teleport にログインできる GitHub アカウントを持っていること。

### 使い方

```bash
cd scripts
./request-prd.sh
```

スクリプトを実行すると、以下を対話的に聞かれます。

- レビュワーのユーザー名（デフォルト: `reviewer-username`）
- 本番クラスタにアクセスする理由

入力が完了すると、内部で以下と同等のコマンドが実行され、Access Request が作成されます。

```bash
tsh request create \
  --roles=prd \
  --reviewers=<reviewer_username> \
  --reason="本番環境へのアクセス"
```

Access Request がレビュワーにより承認されたら、承認済みの Request ID を使って本番クラスタにログインします。

この操作もラッパースクリプト経由で実行できます。

```bash
cd scripts
./login-prd.sh <request-id>

# Request ID を引数で渡さない場合は、対話的に入力を求められます
./login-prd.sh
```

## 本番アクセスの承認/拒否: approve-request.sh（レビュワー向け）

`scripts/approve-request.sh` は、承認待ちの Access Request を一覧し、承認または拒否するためのスクリプトです。

> 注意: このスクリプトは Teleport Auth Service 上で `tctl` コマンドを実行できる権限を持つレビュワー向けです。

### 使い方

```bash
cd scripts
./approve-request.sh
```

スクリプトの挙動:

1. `tctl requests ls` で承認待ちリクエストを取得
2. `fzf` がインストールされていれば `fzf` で、なければシンプルな番号選択で対象リクエストを選択
3. 選択したリクエストに対して、以下のいずれかを選択
   - 承認
   - 拒否
   - キャンセル

それぞれ、内部的には以下のようなコマンドが実行されます。

```bash
# 承認
tctl request approve <request-id> --reason="承認理由"

# 拒否
tctl request deny <request-id> --reason="拒否理由"
```

tsh / tctl コマンドを手動で実行したい場合は、[docs/tsh.md](tsh.md) も参照してください。
