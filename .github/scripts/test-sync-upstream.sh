#!/usr/bin/env bash
# Runs sync-upstream.sh against local repositories, with a `gh` that only
# records what it is asked to do: bash .github/scripts/test-sync-upstream.sh
set -euo pipefail

SCRIPT=$(cd "$(dirname "$0")" && pwd)/sync-upstream.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
g() { git -c core.autocrlf=false "$@"; }

# A `gh` that logs `pr create` and `issue create`, and says nothing is open.
mkdir "$T/bin"
cat >"$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "pr create"|"issue create") echo "$1 $2 $*" >>"$GH_LOG" ;;
  *) [ -n "${GH_OPEN:-}" ] && [ "$GH_OPEN" = "$1" ] && echo 1 || echo 0 ;;
esac
EOF
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH" GH_LOG="$T/gh.log"

# upstream and the fork start the same; besfa is main plus a Besfa commit.
g init -q --bare -b main "$T/upstream.git"
g clone -q "$T/upstream.git" "$T/seed" 2>/dev/null
( cd "$T/seed"
  echo one >a.txt; echo shared >c.txt; g add .; g commit -qm one; g push -q origin main
)
g clone -q --bare "$T/upstream.git" "$T/fork.git"
( cd "$T/seed"; g remote add fork "$T/fork.git"
  g switch -qc besfa; echo besfa >b.txt; g add .; g commit -qm besfa; g push -q fork besfa
  g switch -q main )

run() { # name; the clone it runs in is made fresh from the fork, as in Actions
  rm -rf "$T/work" "$T/gh.log"; : >"$T/gh.log"
  g clone -q "$T/fork.git" "$T/work" 2>/dev/null
  ( cd "$T/work"; UPSTREAM_URL="$T/upstream.git" bash "$SCRIPT" ) >"$T/out.txt" 2>&1 || { cat "$T/out.txt"; echo "FAIL $1: script exited non-zero"; exit 1; }
}
expect() { # name, grep pattern for the gh log, expected count
  local n; n=$(grep -c -- "$2" "$T/gh.log" || true)
  [ "$n" = "$3" ] || { echo "FAIL $1: '$2' x$n, wanted $3"; cat "$T/gh.log" "$T/out.txt"; exit 1; }
  echo "ok   $1"
}

# 1. main has all of upstream; besfa lacks nothing it should merge yet
#    (besfa was cut from main, so main is an ancestor).
run up-to-date
expect "up to date: no PR" "pr create" 0
expect "up to date: no issue" "issue create" 0

# 2. upstream moves cleanly: a sync PR from sync/upstream-<sha> into main.
( cd "$T/seed"; echo two >>a.txt; g commit -qam two; g push -q origin main )
run clean-upstream-commit
expect "clean: one PR" "pr create" 1
expect "clean: into main" "--base main --head sync/upstream-" 1
[ -n "$(g -C "$T/fork.git" branch --list 'sync/upstream-*')" ] || { echo "FAIL clean: sync branch not pushed"; exit 1; }
g -C "$T/fork.git" branch -D "$(g -C "$T/fork.git" branch --list 'sync/upstream-*' | tr -d ' *')" >/dev/null
echo "ok   clean: sync branch pushed"

# 3. an open sync PR is left alone.
rm -rf "$T/work"; g clone -q "$T/fork.git" "$T/work" 2>/dev/null; : >"$T/gh.log"
( cd "$T/work"; GH_OPEN=pr UPSTREAM_URL="$T/upstream.git" bash "$SCRIPT" ) >"$T/out.txt" 2>&1
expect "open PR: not opened again" "pr create" 0

# 4. a conflict opens an issue and no PR: fork and upstream both change c.txt.
g -C "$T/fork.git" update-ref refs/heads/main "$(g -C "$T/seed" rev-parse HEAD~1)"
( cd "$T/seed"; echo forkside >c.txt; g commit -qam fork-edit
  g push -q fork HEAD:refs/heads/main -f
  g reset -q --hard HEAD~1; echo upstreamside >c.txt; g commit -qam upstream-edit; g push -q -f origin main )
run conflict
expect "conflict: issue" "issue create" 1
expect "conflict: no sync PR" "--base main --head sync/upstream-" 0

# 5. besfa lacks main's commits: a main -> besfa PR (head main).
( cd "$T/seed"; g switch -q main; g push -q -f fork main )
run besfa-behind
expect "besfa behind: PR main -> besfa" "--base besfa --head main" 1

# 6. the fork refuses the sync branch, as it does a commit that changes
#    .github/workflows: an issue, no PR, and the script still exits 0.
( cd "$T/seed"; echo three >>a.txt; g commit -qam three; g push -q -f origin main )
printf '#!/bin/sh\nwhile read old new ref; do case "$ref" in refs/heads/sync/*) echo "refusing $ref" >&2; exit 1;; esac; done\n' >"$T/fork.git/hooks/pre-receive"
chmod +x "$T/fork.git/hooks/pre-receive"
run push-rejected
expect "push rejected: issue" "issue create" 1
expect "push rejected: no sync PR" "--base main --head sync/upstream-" 0
rm "$T/fork.git/hooks/pre-receive"

echo "all passed"
