#!/usr/bin/env bash
set -euo pipefail

PROXY="${PROXY:-teleport.example.com:443}"
CLUSTER_NAME="${CLUSTER_NAME:-project-b-prod-default}"

usage() {
  cat <<EOF
Usage: $0 [REQUEST_ID]

Teleport の Access Request が承認された後に、本番クラスタ (prd) へログインするためのラッパースクリプトです。

引数:
  REQUEST_ID   承認済みの Access Request ID

REQUEST_ID を省略した場合は、対話的に入力を求めます。

環境変数:
  PROXY        Teleport プロキシ (default: teleport.example.com:443)
  CLUSTER_NAME Kubernetes クラスタ名 (default: project-b-prod-default)
EOF
  exit 0
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

REQUEST_ID="${1:-}"
if [[ -z "$REQUEST_ID" ]]; then
  read -rp "承認済みの Request ID を入力してください: " REQUEST_ID
fi

if [[ -z "$REQUEST_ID" ]]; then
  echo "Request ID が指定されていません" >&2
  exit 1
fi

echo "Teleport にリクエスト ID でログインします..."
tsh login --proxy="$PROXY" --request-id="$REQUEST_ID"

echo "本番クラスタ ($CLUSTER_NAME) にログインします..."
tsh kube login "$CLUSTER_NAME"

echo "ログイン完了: cluster=$CLUSTER_NAME"
