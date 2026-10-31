# `catalog` (the packaged agents/ + catalog.json) is prepended by default.nix.

usage() {
  cat >&2 <<'EOF'
usage: subagent-catalog list [query]          agents whose name, category or description match
       subagent-catalog show <name>           print a packaged definition
       subagent-catalog status                catalog agents in this project, current or modified
       subagent-catalog enable [-f] <name>... copy into <project>/.claude/agents/
       subagent-catalog disable <name>...     remove copies that match the package
EOF
  exit 2
}

# jj first: in a jj workspace git resolves to the main repo, not this one.
project_root() {
  if command -v jj >/dev/null && jj --ignore-working-copy root 2>/dev/null; then return; fi
  if git rev-parse --show-toplevel 2>/dev/null; then return; fi
  pwd
}

packaged() {
  local f="$catalog/agents/$1.md"
  if [ ! -f "$f" ]; then
    echo "no agent '$1' in the catalog; try: subagent-catalog list $1" >&2
    return 1
  fi
  echo "$f"
}

[ $# -ge 1 ] || usage
cmd=$1
shift

case $cmd in
  list)
    jq -r --arg q "${1:-}" '
      .[]
      | select(($q | length) == 0
          or ([.name, .category, .description] | join(" ") | ascii_downcase | contains($q | ascii_downcase)))
      | "\(.category)\t\(.name)\t\(.description)"
    ' "$catalog/catalog.json"
    ;;
  show)
    [ $# -eq 1 ] || usage
    cat "$(packaged "$1")"
    ;;
  status)
    dir="$(project_root)/.claude/agents"
    [ -d "$dir" ] || exit 0
    for f in "$dir"/*.md; do
      [ -e "$f" ] || continue
      name=$(basename "$f" .md)
      src="$catalog/agents/$name.md"
      [ -f "$src" ] || continue
      if cmp -s "$f" "$src"; then echo "current   $name"; else echo "modified  $name"; fi
    done
    ;;
  enable)
    force=0
    if [ "${1:-}" = -f ]; then force=1; shift; fi
    [ $# -ge 1 ] || usage
    dir="$(project_root)/.claude/agents"
    mkdir -p "$dir"
    status=0
    for name in "$@"; do
      src=$(packaged "$name") || { status=1; continue; }
      dst="$dir/$name.md"
      if [ -e "$dst" ] && ! cmp -s "$dst" "$src" && [ $force -eq 0 ]; then
        # Could be a local edit or an older package version; only the user knows.
        echo "$dst differs from the packaged definition; diff it, then rerun with -f to overwrite" >&2
        status=1
        continue
      fi
      install -m 0644 "$src" "$dst"
      echo "enabled $name -> $dst"
    done
    exit $status
    ;;
  disable)
    [ $# -ge 1 ] || usage
    dir="$(project_root)/.claude/agents"
    status=0
    for name in "$@"; do
      dst="$dir/$name.md"
      if [ ! -e "$dst" ]; then
        echo "$name is not enabled in $dir" >&2
        status=1
      elif src=$(packaged "$name") && cmp -s "$dst" "$src"; then
        rm "$dst"
        echo "disabled $name"
      else
        echo "$dst differs from the packaged definition; not removing it" >&2
        status=1
      fi
    done
    exit $status
    ;;
  *) usage ;;
esac
