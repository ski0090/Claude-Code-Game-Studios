#!/bin/bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   0. the payload's "cwd"      -> it, or its git top level, when that holds
#      project.yaml or .claude/hooks/session-start.sh. Every hook gets one JSON
#      object on stdin, and its cwd is where the session works. A desktop
#      worktree session runs hooks from the main checkout (the working
#      directory and CLAUDE_PROJECT_DIR both name it), so rules 1-3 alone read
#      and write the main checkout's state. stdin is read here once, bounded,
#      and handed back unchanged: the hook's own read below sees the payload.
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured),
#      unless cwd is itself named .claude: a stray .claude/.claude/ would
#      make .claude/ a root, and the hooks would write .claude/production/
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment),
#      unless it names a .claude folder, for the same reason as rule 2
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
CCGS_IN=""
if [ ! -t 0 ]; then
  if command -v timeout >/dev/null 2>&1; then CCGS_IN=$(timeout 2 cat 2>/dev/null); else CCGS_IN=$(cat 2>/dev/null); fi
  exec <<<"$CCGS_IN"
fi
CCGS_CWD=""; _ccgs_re='"cwd"[[:space:]]*:[[:space:]]*"([^"]*)"'; _ccgs_bs='\'
[[ $CCGS_IN =~ $_ccgs_re ]] && CCGS_CWD=${BASH_REMATCH[1]//"$_ccgs_bs$_ccgs_bs"/$_ccgs_bs}
_ccgs_is_root() { [ -f "$1/project.yaml" ] || [ -f "$1/.claude/hooks/session-start.sh" ]; }
if [ -n "$CCGS_CWD" ] && ! _ccgs_is_root "$CCGS_CWD"; then
  CCGS_CWD=$(git -C "$CCGS_CWD" rev-parse --show-toplevel 2>/dev/null)
fi
if [ -n "$CCGS_CWD" ] && _ccgs_is_root "$CCGS_CWD"; then
  CCGS_ROOT="$CCGS_CWD"
elif [ -f "project.yaml" ] || { [ -d ".claude" ] && [ "${PWD##*/}" != ".claude" ]; }; then
  CCGS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ] && case "${CLAUDE_PROJECT_DIR%/}" in */.claude|*\\.claude) false ;; *) true ;; esac; then
  CCGS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code PreCompact hook: log the compaction. Nothing else.
#
# PRINTS NOTHING, ON PURPOSE. Claude Code writes PreCompact stdout to the debug
# log and discards its systemMessage (hooks documentation), so a state summary
# printed here reached no one -- and gathering it cost git and grep spawns on
# every compaction. What survives a compaction is the file on disk:
# SessionStart fires again with source `compact`, and session-start.sh shows
# the CHECKPOINT from production/session-state/active.md then.

# features.session_state: off => this hook is a no-op. Default `on`; see
# session_state_enabled() in yaml-helper.sh.
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh
    session_state_enabled || exit 0
fi

SESSION_LOG_DIR="production/session-logs"
mkdir -p "$SESSION_LOG_DIR" 2>/dev/null
echo "Context compaction occurred at $(date)." \
    >> "$SESSION_LOG_DIR/compaction-log.txt" 2>/dev/null

exit 0
