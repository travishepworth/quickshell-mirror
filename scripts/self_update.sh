#!/usr/bin/env bash
#
# Description: Checks for and applies axiom updates. Releases are `v*` tags
#              on the clone's remote; an update fast-forwards to the newest.
# Usage:       self_update.sh check [dir]
#              self_update.sh apply <tag> [dir]
#              dir defaults to the repo this script is in. Prints one JSON
#              object: { current, commit, latest, state, ahead, behind,
#              blocked, notes, error }
#                state   "uptodate" | "available" | "diverged" | ""
#                blocked why it can't update: "dirty" (changed tracked
#                        files), "diverged" (local commits), "branch" (a
#                        branch other than main/master), "nogit", or ""
#              Never stashes, resets or forces: a blocked clone is left as
#              it is.

set -uo pipefail

command -v jq >/dev/null || { echo '{"error": "jq is not installed"}'; exit 1; }

action=${1:-check}
tag=""
if [[ "$action" == "apply" ]]; then
  tag=${2:-}
  dir=${3:-}
else
  dir=${2:-}
fi
dir=${dir:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}

# Never wait on a password or host-key prompt
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes"

g() { git -C "$dir" "$@"; }

emit() {
  jq -cn --arg current "${current:-}" --arg commit "${commit:-}" --arg latest "${latest:-}" \
    --arg state "${state:-}" --argjson ahead "${ahead:-false}" --argjson behind "${behind:-0}" \
    --arg blocked "${blocked:-}" --arg notes "${notes:-}" --arg error "${1:-}" \
    '{current: $current, commit: $commit, latest: $latest, state: $state, ahead: $ahead,
      behind: $behind, blocked: $blocked, notes: $notes, error: $error}'
}

if ! g rev-parse --git-dir >/dev/null 2>&1; then
  blocked=nogit
  emit "$dir is not a git clone"
  exit 0
fi

branch=$(g symbolic-ref --quiet --short HEAD 2>/dev/null || true)

fetch() {
  local remote
  remote=$( [[ -n "$branch" ]] && g config "branch.$branch.remote" 2>/dev/null || true)
  remote=${remote:-origin}
  local err
  if ! err=$(timeout 60 git -C "$dir" fetch --quiet --force --no-tags "$remote" 'refs/tags/v*:refs/tags/v*' 2>&1); then
    # Offline: still report the installed version, from the tags we have
    inspect
    emit "$(first_error "${err:-fetch from $remote timed out}")"
    exit 0
  fi
}

# git's reason, rather than its closing advice
first_error() {
  printf '%s\n' "$1" | grep -m 1 -E '^(fatal|error):' | sed -E 's/^(fatal|error): //' || printf '%s\n' "$1" | tail -n 1
}

# Fills current/commit/latest/state/ahead/behind/blocked/notes
inspect() {
  current=$(g describe --tags --abbrev=0 --match 'v*' HEAD 2>/dev/null || true)
  commit=$(g rev-parse --short HEAD)
  latest=$(g tag -l 'v*' --sort=-v:refname | head -n 1)
  state="" ahead=false behind=0 blocked="" notes=""
  [[ -z "$latest" ]] && return
  notes=$(g tag -l --format='%(contents)' "$latest" | sed -e '/^-----BEGIN PGP SIGNATURE-----/,$d')
  if g merge-base --is-ancestor "$latest" HEAD; then
    state=uptodate
    [[ "$(g rev-parse HEAD)" != "$(g rev-parse "$latest^{commit}")" ]] && ahead=true
    return
  fi
  if g merge-base --is-ancestor HEAD "$latest"; then
    state=available
    behind=$(g rev-list --count "HEAD..$latest")
  else
    state=diverged
    blocked=diverged
    return
  fi
  if [[ -n "$branch" && "$branch" != "main" && "$branch" != "master" ]]; then
    blocked=branch
  elif [[ -n "$(g status --porcelain --untracked-files=no)" ]]; then
    blocked=dirty
  fi
}

case "$action" in
check)
  fetch
  inspect
  emit
  ;;
apply)
  [[ -z "$tag" ]] && { emit "no tag given"; exit 1; }
  inspect
  if [[ "$state" != "available" || "$latest" != "$tag" ]]; then
    emit "$tag is not an available update"
    exit 1
  fi
  if [[ -n "$blocked" ]]; then
    emit "blocked: $blocked"
    exit 1
  fi
  if [[ -n "$branch" ]]; then
    out=$(g merge --ff-only --quiet "$tag" 2>&1)
  else
    out=$(g checkout --quiet "$tag" 2>&1)
  fi
  status=$?
  inspect
  if [[ $status -ne 0 ]]; then
    emit "$(first_error "$out")"
    exit 1
  fi
  emit
  ;;
*)
  echo "Usage: $0 check [dir] | apply <tag> [dir]" >&2
  exit 2
  ;;
esac
