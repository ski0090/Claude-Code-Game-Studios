#!/usr/bin/env bash
# Keeps this fork current with Donchitos/Claude-Code-Game-Studios, as pull
# requests a person merges:
#   1. upstream main -> main, when upstream has commits main lacks.
#   2. main -> besfa, when besfa lacks commits main has.
# Merges, never rebases: both branches are shared and merged as squashes or
# merge commits, so rewriting them would need a force push. A merge that
# conflicts opens an issue naming the files instead of a PR.
#
# Needs: git, gh (GH_TOKEN, and GH_REPO or a clone with an origin remote), and
# a clone with full history whose origin is this fork.
# Env: UPSTREAM_URL (default: Donchitos' repository), DRY_RUN=1 to print the
# gh calls instead of making them.
set -euo pipefail

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
UPSTREAM_URL=${UPSTREAM_URL:-https://github.com/Donchitos/Claude-Code-Game-Studios.git}
BESFA=besfa

git config user.name  "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch --quiet upstream main
git fetch --quiet origin main "$BESFA"

gh() { if [ "${DRY_RUN:-}" = 1 ]; then echo "gh $*"; else command gh "$@"; fi; }
# Lists, which a dry run still has to read.
gh_read() { command gh "$@"; }
count_open() { gh_read pr list --state open "$@" --json number --jq length; }

# 1. upstream main -> main
if git merge-base --is-ancestor upstream/main origin/main; then
  echo "main has everything upstream main has."
elif [ "$(gh_read pr list --state open --base main --json headRefName --jq '[.[]|select(.headRefName|startswith("sync/upstream-"))]|length')" != 0 ]; then
  echo "A sync PR from upstream is already open; leaving it to be merged."
else
  sha=$(git rev-parse --short upstream/main)
  branch="sync/upstream-$sha"
  git switch --quiet -c "$branch" origin/main
  if git merge --no-edit --quiet -m "Merge upstream main ($sha) into main" upstream/main; then
    # The workflow's token cannot push a commit that changes .github/workflows,
    # which upstream may one day add; say so instead of failing quietly.
    if git push --quiet origin "$branch" 2>"$T/push.err"; then
      gh pr create --base main --head "$branch" \
        --title "Merge upstream main ($sha) into main" \
        --body "$(printf '%s\n' \
          "Upstream's main moved. This merges it into the fork's main with no conflicts." \
          "" \
          "**Merge it with a merge commit, not a squash**, so main keeps upstream's history and the next sync sees it." \
          "" \
          "Skim what upstream changed in \`.claude/\` before merging: hooks and skills run in every game that follows the \`besfa\` branch." \
          "" \
          "Opened by .github/workflows/sync-upstream.yml.")"
    else
      git switch --quiet --detach origin/main
      if [ "$(gh_read issue list --state open --search "\"Upstream sync push rejected\" in:title" --json number --jq length)" = 0 ]; then
        gh issue create \
          --title "Upstream sync push rejected at $sha" \
          --body "$(printf '%s\n' \
            "Merging upstream main ($sha) into main worked, but pushing the branch was rejected:" \
            "" \
            '```' "$(cat "$T/push.err")" '```' \
            "" \
            "Upstream probably changed \`.github/workflows/\`, which the workflow's token may not push. Merge \`upstream/main\` into \`main\` by hand and open the PR." \
            "" \
            "Opened by .github/workflows/sync-upstream.yml.")"
      else
        echo "A push-rejected issue is already open."
      fi
    fi
  else
    files=$(git diff --name-only --diff-filter=U)
    git merge --abort
    git switch --quiet --detach origin/main
    if [ "$(gh_read issue list --state open --search "\"Upstream sync conflict\" in:title" --json number --jq length)" = 0 ]; then
      gh issue create \
        --title "Upstream sync conflict at $sha" \
        --body "$(printf '%s\n' \
          "Merging upstream main ($sha) into main conflicts in:" \
          "" \
          "$(printf '%s\n' "$files" | sed 's/^/- `/; s/$/`/')" \
          "" \
          "Merge \`upstream/main\` into \`main\` by hand, resolve these, and open the PR. This issue closes itself nowhere: close it once the PR merges." \
          "" \
          "Opened by .github/workflows/sync-upstream.yml.")"
    else
      echo "A sync conflict issue is already open."
    fi
  fi
fi

# 2. main -> besfa (after step 1 may have changed nothing on main yet)
if git merge-base --is-ancestor origin/main "origin/$BESFA"; then
  echo "$BESFA has everything main has."
elif [ "$(count_open --base "$BESFA" --head main)" != 0 ]; then
  echo "A main -> $BESFA PR is already open."
else
  gh pr create --base "$BESFA" --head main \
    --title "Merge main into $BESFA" \
    --body "$(printf '%s\n' \
      "Main has commits $BESFA lacks. This brings them in, so \`$BESFA\`, which games follow, contains \`main\`." \
      "" \
      "**Merge it with a merge commit, not a squash.** If it shows conflicts, merge \`main\` into \`$BESFA\` by hand and resolve them there." \
      "" \
      "Opened by .github/workflows/sync-upstream.yml.")"
fi
