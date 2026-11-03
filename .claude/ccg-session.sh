#!/usr/bin/env bash
# SessionStart wrapper for a game that mounts ccg as the `.ccg` submodule and
# links .claude/{agents,docs,hooks,rules,scripts} and each skill into it
# (duskhold; `besfa new --ccgs` copies this file into the game's .claude/).
#
# A new worktree starts with .ccg empty, so its .claude/hooks link leads
# nowhere and no CCGS hook can run until something fills it. This file is
# copied, not linked, so it runs while .ccg is still empty. It fills .ccg in
# CLAUDE_PROJECT_DIR and in the checkout the payload's cwd is in (a desktop
# worktree session runs its hooks from the main checkout, so only the payload
# names the worktree), then runs the CCGS hook with the same payload.
# In a checkout without a .ccg submodule (ccg itself) it only runs the hook.
#
# Usage: bash .claude/ccg-session.sh <hook> [--fill] < payload.json
#   <hook>  the CCGS hook to run, .claude/hooks/<hook>.sh
#   --fill  fill an empty .ccg first; without it the hook is skipped until
#           .ccg is filled (SessionStart hooks run in parallel: one fills)
# Exit: the hook's own, or 0 when it was skipped. Needs git; no Python.
p=$(cat)
re='"cwd"[[:space:]]*:[[:space:]]*"([^"]*)"'; bs='\'
cwd=""; [[ $p =~ $re ]] && cwd=${BASH_REMATCH[1]//"$bs$bs"/$bs}
top=""; [ -n "$cwd" ] && top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
for root in "${CLAUDE_PROJECT_DIR:-.}" "$top"; do
  [ -n "$root" ] && [ ! -e "$root/.ccg/.claude" ] || continue
  grep -Eqs '^[[:space:]]*path[[:space:]]*=[[:space:]]*\.ccg[[:space:]]*$' "$root/.gitmodules" || continue
  [ "${2:-}" = --fill ] || exit 0
  git -C "$root" submodule update --init --quiet .ccg
done
hook="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/$1.sh"
[ -f "$hook" ] || exit 0
printf '%s' "$p" | bash "$hook"
