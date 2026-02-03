#!/usr/bin/env bash
# 変更されたファイルが属するディレクトリを抽出するスクリプト
#
# 使用方法:
#   ./filter-dirs.sh <terraform_trigger_changed> <all_dirs_json> <filter_outputs_json>
#
# 引数:
#   terraform_trigger_changed: "true" or "false" - グローバルフィルタがマッチしたかどうか
#   all_dirs_json: dirs.json の内容（JSON配列）
#   filter_outputs_json: dorny/paths-filter の outputs（JSON）
#
# 出力:
#   dirs=<json_array> を標準出力に出力（GITHUB_OUTPUT用）

set -euo pipefail

terraform_trigger_changed="${1:-false}"
all_dirs="${2:-[]}"
filter_outputs="${3:-{\}}"

echo "Terraform trigger (global filter) changed: $terraform_trigger_changed" >&2
echo "All dirs: $all_dirs" >&2

# グローバルフィルタ (terraform_trigger) にマッチした場合は全ディレクトリを返す
if [ "$terraform_trigger_changed" = "true" ]; then
  echo "Global filter matched - returning all directories" >&2
  echo "dirs=$all_dirs"
  exit 0
fi

# jq で個別ディレクトリフィルタをチェック（for ループを jq 内部処理に置き換え）
changed_dirs=$(jq -c --argjson outputs "$filter_outputs" '
  [.[] | select(
    ("dir_" + gsub("/"; "_")) as $key |
    ($outputs[$key] // "false") == "true"
  )]
' <<< "$all_dirs")

# デバッグ出力
jq -r --argjson outputs "$filter_outputs" '
  .[] | ("dir_" + gsub("/"; "_")) as $key |
  "Checking filter \($key): \($outputs[$key] // "false")"
' <<< "$all_dirs" >&2

if [ "$changed_dirs" = "[]" ]; then
  echo "No changes matched - returning empty array" >&2
else
  echo "Changed directories: $changed_dirs" >&2
fi

echo "dirs=$changed_dirs"
