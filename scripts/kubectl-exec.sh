#!/usr/bin/env bash
set -euo pipefail

# 使い方:
#   ./kubectl-exec.sh                              # クラスタ選択 → applicationアプリへexec
#   ./kubectl-exec.sh -a batch-1                   # クラスタ選択 → batch-1アプリへexec
#   ./kubectl-exec.sh -u your-username                 # GitHubユーザー名を指定
#   ./kubectl-exec.sh -h                           # ヘルプ表示
#
# 環境変数でも指定可能:
#   APP_TYPE=batch-1 GITHUB_USER=xxx ./kubectl-exec.sh

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -a APP      アプリ種別を指定 (application|batch-1|batch-3|admin) [default: application]
  -u USER     GitHubユーザー名を指定
  -h          このヘルプを表示

Examples:
  $0                              # クラスタ選択→applicationにexec
  $0 -a batch-1                   # クラスタ選択→batch-1にexec
  $0 -a admin                     # クラスタ選択→adminにexec
  $0 -u your-username                 # GitHubユーザー指定
EOF
  exit 0
}

APP_TYPE="${APP_TYPE:-application}"
GITHUB_USER="${GITHUB_USER:-}"
NAMESPACE="${NAMESPACE:-default}"
TELEPORT_PROXY="${TELEPORT_PROXY:-teleport.example.com:443}"

while getopts "a:u:h" opt; do
  case "$opt" in
    a) APP_TYPE="$OPTARG" ;;
    u) GITHUB_USER="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

# ==============================
# Teleport ログイン確認
# ==============================
if ! tsh status 2>&1 | grep -q "Logged in as:"; then
  echo "🔐 Teleport にログインします..."
  if [[ -z "$GITHUB_USER" ]]; then
    read -rp "GitHub ユーザー名を入力してください: " GITHUB_USER
  fi
  tsh login --proxy="$TELEPORT_PROXY" --auth=github --user="$GITHUB_USER"
fi

# ==============================
# クラスタ一覧 → 選択
# ==============================
# tsh kube ls の出力は環境によって列が多少異なるため、
# 「1列目をクラスタ名」とみなしてヘッダや罫線を除外します。
mapfile -t CLUSTERS < <(
  tsh kube ls 2>/dev/null \
    | awk 'NR==1 {next} /^[[:space:]]*$/ {next} /^-+/ {next} {print $1}' \
    | sort -u
)

if [[ ${#CLUSTERS[@]} -eq 0 ]]; then
  echo "❌ Teleport から Kubernetes クラスタ一覧を取得できませんでした。(tsh kube ls)" >&2
  exit 1
fi

echo "Kubernetes クラスタを選択してください:"
select KUBE_CLUSTER in "${CLUSTERS[@]}"; do
  if [[ -n "${KUBE_CLUSTER:-}" ]]; then
    break
  fi
done

# ==============================
# Kubernetes クラスタにログイン
# ==============================
echo "🔐 Kubernetes クラスタにログインします (cluster: $KUBE_CLUSTER)"
tsh kube login "$KUBE_CLUSTER"

# ==============================
# Pod prefix / namespace の決定 (クラスタ名から推定)
# ==============================
# クラスタ種別の判定
#  - project-b-* クラスタ: namespace=prd/stg, Pod=api/sidekiq
#  - project-a-* クラスタ: namespace=default, Pod=app-*
POD_ENV="staging"
if echo "$KUBE_CLUSTER" | grep -Eqi 'prod|prd'; then
  POD_ENV="prod"
elif echo "$KUBE_CLUSTER" | grep -Eqi 'stag|stg'; then
  POD_ENV="staging"
fi

if echo "$KUBE_CLUSTER" | grep -Eqi '^project-b'; then
  # project-b クラスタの場合
  if [[ "$POD_ENV" == "prod" ]]; then
    NAMESPACE="prd"
  else
    NAMESPACE="stg"
  fi
  # project-b では APP_TYPE を直接 Pod プレフィックスとして使用
  case "$APP_TYPE" in
    application) POD_PREFIX="api" ;;
    *)           POD_PREFIX="$APP_TYPE" ;;
  esac
else
  # project-a クラスタの場合 (既存ロジック)
  NAMESPACE="${NAMESPACE:-default}"
  if [[ "$APP_TYPE" == "admin" ]]; then
    POD_PREFIX="admin-app-${POD_ENV}-application"
  else
    POD_PREFIX="app-${POD_ENV}-${APP_TYPE}"
  fi
fi

# Running の Pod 一覧を取得
mapfile -t PODS < <(kubectl get pods -n "$NAMESPACE" \
  --no-headers \
  -o custom-columns=":metadata.name,:status.phase" \
  | grep "^${POD_PREFIX}-" \
  | grep "Running" \
  | awk '{print $1}')

if [[ ${#PODS[@]} -eq 0 ]]; then
  echo "❌ Running 状態の ${POD_PREFIX} Pod が見つかりませんでした。(namespace: $NAMESPACE)" >&2
  echo "   選択クラスタ: $KUBE_CLUSTER" >&2
  exit 1
fi

echo "Namespace: $NAMESPACE"
echo "Cluster:   $KUBE_CLUSTER"
echo "App:       $POD_PREFIX"
echo "Pod を選択してください:"
select POD in "${PODS[@]}"; do
  if [[ -n "${POD:-}" ]]; then
    break
  fi
done

# 通常コンテナ + ephemeral コンテナ名を 1 行 1 名で取得
mapfile -t CONTAINERS < <(
  {
    kubectl get pod "$POD" -n "$NAMESPACE" \
      -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}';
    kubectl get pod "$POD" -n "$NAMESPACE" \
      -o jsonpath='{range .spec.ephemeralContainers[*]}{.name}{"\n"}{end}' 2>/dev/null || true
  } | sed '/^$/d' | sort -u
)

if [[ ${#CONTAINERS[@]} -eq 0 ]]; then
  echo "❌ コンテナが見つかりませんでした。" >&2
  exit 1
elif [[ ${#CONTAINERS[@]} -eq 1 ]]; then
  CONTAINER_NAME="${CONTAINERS[0]}"
else
  echo "コンテナを選択してください:"
  select CONTAINER_NAME in "${CONTAINERS[@]}"; do
    if [[ -n "${CONTAINER_NAME:-}" ]]; then
      break
    fi
  done
fi

echo "✅ exec 先: $POD (${CONTAINER_NAME}) @ $NAMESPACE"
echo "----------------------------------------"

kubectl exec -it "$POD" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- bash
