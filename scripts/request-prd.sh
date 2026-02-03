#!/bin/bash
set -euo pipefail

PROXY="teleport.example.com:443"

# ログイン確認
if ! tsh status &>/dev/null; then
  echo "Teleportにログインします..."
  tsh login --proxy="$PROXY" --auth=github
fi

# レビュワー入力
read -rp "レビュワー [reviewer-username]: " reviewer
reviewer="${reviewer:-reviewer-username}"
read -rp "クラスタにアクセスする理由: " reason

# リクエスト作成
tsh request create --roles=prd --reviewers="$reviewer" --reason="${reason:-本番環境へのアクセス}"

echo ""
echo "リクエストが作成されました。承認後に以下を実行:"
echo "  tsh login --proxy=$PROXY --request-id=<request-id>"
echo "  tsh kube login project-b-prod-default"
