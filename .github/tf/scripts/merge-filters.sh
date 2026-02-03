#!/usr/bin/env bash
# フィルタファイルをマージし、各ディレクトリのフィルタを動的に追加するスクリプト
#
# 使用方法:
#   ./merge-filters.sh <dirs_file>
#
# 出力:
#   /tmp/filters.merged.yaml にマージ済みフィルタを出力

set -euo pipefail

DIRS_FILE="${1:-.github/tf/config/local/dirs.json}"
GLOBAL_FILTERS=".github/tf/config/filters.yaml"
LOCAL_FILTERS=".github/tf/config/local/filters.local.yaml"
MERGED_FILTERS="/tmp/filters.merged.yaml"

# 相対パス（../を含む）を絶対パスに変換する関数
# 引数: $1 = ベースディレクトリ, $2 = 相対パス
resolve_relative_path() {
  local base_dir="$1"
  local rel_path="$2"
  local glob_suffix=""

  # glob パターン部分（** や *）を分離
  if [[ "$rel_path" == *"/**" ]]; then
    glob_suffix="/**"
    rel_path="${rel_path%/**}"
  elif [[ "$rel_path" == *"/*" ]]; then
    glob_suffix="/*"
    rel_path="${rel_path%/*}"
  fi

  # realpath -m で正規化（存在しないパスも処理可能）
  local normalized
  normalized=$(realpath -m --relative-to=. "${base_dir}/${rel_path}" 2>/dev/null | sed 's|^\./||')
  echo "${normalized}${glob_suffix}"
}

# グローバルフィルタの存在確認
if [ ! -f "$GLOBAL_FILTERS" ]; then
  echo "Error: Global filters file $GLOBAL_FILTERS not found" >&2
  exit 1
fi

# グローバルフィルタをベースにする
cp "$GLOBAL_FILTERS" "$MERGED_FILTERS"

# ローカルフィルタがあればマージ
if [ -f "$LOCAL_FILTERS" ]; then
  echo "Merging $LOCAL_FILTERS into $MERGED_FILTERS"
  yq eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1)' \
    "$MERGED_FILTERS" "$LOCAL_FILTERS" > "$MERGED_FILTERS.tmp"
  mv "$MERGED_FILTERS.tmp" "$MERGED_FILTERS"
fi

# dirs.json の各ディレクトリを個別のフィルタとして追加
if [ -f "$DIRS_FILE" ]; then
  echo "Adding individual directory filters from $DIRS_FILE"

  for dir in $(jq -r '.[]' < "$DIRS_FILE"); do
    # ディレクトリ名からスラッシュを除去してフィルタ名を作成 (例: envs/sandbox -> envs_sandbox)
    filter_name=$(echo "$dir" | sed 's/\//_/g')

    # まずディレクトリ自身のパスを追加
    paths="[\"$dir/**\"]"

    # 追加トリガーパスを処理（相対パスを絶対パスに変換）
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue

      if [[ "$pattern" == ../* ]]; then
        # 相対パスを絶対パスに変換（複数階層の ../ に対応）
        resolved=$(resolve_relative_path "$dir" "$pattern")

        # 解決されたパスが有効な場合のみ追加（空やルートでない）
        if [[ -n "$resolved" && "$resolved" != "/" ]]; then
          echo "  Resolved: $pattern -> $resolved (for $dir)"
          paths=$(echo "$paths" | jq -c --arg p "$resolved" '. + [$p]')
        fi
      else
        # 相対パスでない場合はそのまま追加
        paths=$(echo "$paths" | jq -c --arg p "$pattern" '. + [$p]')
      fi
    done < <(yq eval '.dir_extra_triggers[]' "$MERGED_FILTERS" 2>/dev/null || true)

    echo "Adding filter: dir_${filter_name} with paths: $paths"
    yq eval -i ".[\"dir_${filter_name}\"] = $paths" "$MERGED_FILTERS"
  done

  # dir_extra_triggers は dorny/paths-filter には不要なので削除
  yq eval -i 'del(.dir_extra_triggers)' "$MERGED_FILTERS"
fi

echo "Merged filters:"
cat "$MERGED_FILTERS"
