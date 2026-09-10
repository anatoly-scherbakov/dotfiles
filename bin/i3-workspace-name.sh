# Shared i3 workspace naming: numeric prefix plus irene symbol.
# Sourced by irene and i3-reorder-workspace. Not for PATH.

i3_workspace_prefixes=(
  "🄌" "❶" "❷" "❸" "❹" "❺" "❻" "❼" "❽" "❾" "❿" "➕" "➖" "✖" "➗"
)

i3_workspace_prefix() {
  local num="$1"
  if [[ "$num" =~ ^[0-9]+$ ]] && ((num < ${#i3_workspace_prefixes[@]})); then
    printf '%s' "${i3_workspace_prefixes[$num]}"
  fi
}

i3_workspace_numbered_name() {
  local num="$1"
  local title="$2"
  local prefix
  prefix="$(i3_workspace_prefix "$num")"
  if [[ -n "$prefix" ]]; then
    printf '%s:%s%s' "$num" "$prefix" "$title"
  else
    printf '%s: %s' "$num" "$title"
  fi
}

i3_workspace_title() {
  local name="$1"
  local num="$2"
  if [[ "$num" == "-1" || -z "$num" ]]; then
    printf '%s' "$name"
    return
  fi
  if [[ "$name" == "$num" ]]; then
    printf ''
    return
  fi
  if [[ "$name" == "$num:"* ]]; then
    local rest prefix
    rest="${name#"$num:"}"
    prefix="$(i3_workspace_prefix "$num")"
    if [[ -n "$prefix" && "$rest" == "$prefix"* ]]; then
      printf '%s' "${rest#"$prefix"}"
      return
    fi
    printf '%s' "${rest# }"
    return
  fi
  printf '%s' "$name"
}

i3_workspace_unnumbered_name() {
  local name="$1"
  local num="$2"
  local title
  title="$(i3_workspace_title "$name" "$num")"
  if [[ -n "$title" ]]; then
    if [[ "$title" =~ ^[0-9] ]]; then
      printf '%s%s' "$(i3_workspace_prefix "$num")" "$title"
    else
      printf '%s' "$title"
    fi
  else
    i3_workspace_prefix "$num"
  fi
}
