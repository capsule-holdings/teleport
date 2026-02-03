#!/bin/bash
set -euo pipefail

# リクエスト一覧を取得（ヘッダーと区切り線を除外）
requests=$(tctl requests ls 2>/dev/null | grep -v '^-' | tail -n +2)

if [ -z "$requests" ]; then
  echo "承認待ちのリクエストはありません"
  exit 0
fi

# fzfで選択（インストールされていない場合はselectを使用）
if command -v fzf &> /dev/null; then
  selected=$(echo "$requests" | fzf --header="承認するリクエストを選択 (Ctrl+C でキャンセル)")
else
  echo "リクエスト一覧:"
  echo "$requests" | nl -w2 -s') '
  echo ""
  read -rp "番号を選択: " num
  selected=$(echo "$requests" | sed -n "${num}p")
fi

if [ -z "$selected" ]; then
  echo "キャンセルしました"
  exit 0
fi

# リクエストIDを抽出（最初のカラム）
request_id=$(echo "$selected" | awk '{print $1}')

echo ""
echo "選択されたリクエスト:"
echo "$selected"
echo ""

# 承認/拒否を選択
echo "アクション:"
echo "1) 承認"
echo "2) 拒否"
echo "3) キャンセル"
read -rp "選択 [1-3]: " action

case $action in
  1)
    read -rp "承認理由: " reason
    tctl request approve "$request_id" --reason="${reason:-承認}"
    echo "承認しました: $request_id"
    ;;
  2)
    read -rp "拒否理由: " reason
    tctl request deny "$request_id" --reason="${reason:-拒否}"
    echo "拒否しました: $request_id"
    ;;
  *)
    echo "キャンセルしました"
    exit 0
    ;;
esac
