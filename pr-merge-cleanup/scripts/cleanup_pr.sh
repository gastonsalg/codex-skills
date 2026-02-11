#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") [<pr-number-or-url>]

Examples:
  $(basename "$0") 123
  $(basename "$0") https://github.com/owner/repo/pull/123
  $(basename "$0")            # infer PR from current branch
USAGE
}

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

select_target_branch() {
  if git show-ref --verify --quiet refs/heads/main; then
    printf 'main'
    return 0
  fi

  if git show-ref --verify --quiet refs/heads/master; then
    printf 'master'
    return 0
  fi

  if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
    printf 'main'
    return 0
  fi

  if git ls-remote --exit-code --heads origin master >/dev/null 2>&1; then
    printf 'master'
    return 0
  fi

  return 1
}

ensure_branch_checked_out() {
  local branch="$1"

  if git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null; then
    git checkout "$branch"
    return 0
  fi

  if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
    git checkout -b "$branch" --track "origin/$branch"
    return 0
  fi

  die "Unable to checkout target branch '$branch' locally or from origin"
}

remove_head_worktrees() {
  local head_branch="$1"
  local repo_root="$2"
  local removed=0

  local wt_path=""
  local wt_branch=""
  local wt_locked=0

  process_entry() {
    if [[ -z "$wt_path" ]]; then
      return 0
    fi

    if [[ "$wt_branch" != "refs/heads/${head_branch}" ]]; then
      return 0
    fi

    if [[ "$wt_path" == "$repo_root" ]]; then
      warn "Skipping current worktree path: $wt_path"
      return 0
    fi

    if [[ "$wt_locked" -eq 1 ]]; then
      warn "Skipping locked worktree for branch '$head_branch': $wt_path"
      return 0
    fi

    if [[ -n "$(git -C "$wt_path" status --porcelain 2>/dev/null || true)" ]]; then
      warn "Skipping dirty worktree for branch '$head_branch': $wt_path"
      return 0
    fi

    log "Removing worktree: $wt_path"
    git worktree remove "$wt_path"
    removed=1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      process_entry
      wt_path=""
      wt_branch=""
      wt_locked=0
      continue
    fi

    case "$line" in
      worktree\ *)
        wt_path="${line#worktree }"
        ;;
      branch\ *)
        wt_branch="${line#branch }"
        ;;
      locked*)
        wt_locked=1
        ;;
    esac
  done < <(git worktree list --porcelain)

  process_entry

  log "Pruning stale worktree metadata"
  git worktree prune

  if [[ "$removed" -eq 0 ]]; then
    log "No removable worktrees found for branch '$head_branch'"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -gt 1 ]]; then
  usage
  exit 1
fi

require_cmd git
require_cmd gh

PR_SELECTOR="${1:-}"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Not inside a git repository"
cd "$repo_root"

# Hard stop on dirty repository state to avoid partial cleanup.
if [[ -n "$(git status --porcelain)" ]]; then
  die "Working tree is dirty. Commit/stash/discard changes before cleanup."
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  die "Remote 'origin' is required for this cleanup workflow"
fi

target_branch="$(select_target_branch)" || die "Could not determine target branch (main/master)"

if [[ -n "$PR_SELECTOR" ]]; then
  log "Resolving PR metadata for selector: $PR_SELECTOR"
  pr_fields="$(gh pr view "$PR_SELECTOR" --json number,url,state,mergedAt,headRefName,baseRefName,headRepositoryOwner,headRepository --jq '[.number, .url, .state, (.mergedAt // "__NULL__"), .headRefName, .baseRefName, (.headRepositoryOwner.login // ""), (.headRepository.name // "")] | @tsv')" \
    || die "Unable to resolve PR '$PR_SELECTOR' via gh"
else
  log "Resolving PR metadata from current branch"
  pr_fields="$(gh pr view --json number,url,state,mergedAt,headRefName,baseRefName,headRepositoryOwner,headRepository --jq '[.number, .url, .state, (.mergedAt // "__NULL__"), .headRefName, .baseRefName, (.headRepositoryOwner.login // ""), (.headRepository.name // "")] | @tsv')" \
    || die "Unable to resolve PR from current branch via gh"
fi

IFS=$'\t' read -r pr_number pr_url pr_state merged_at head_branch base_branch head_owner head_repo <<<"$pr_fields"

log "PR #$pr_number: $pr_url"
log "State: $pr_state"

if [[ "$pr_state" != "MERGED" && "$merged_at" == "__NULL__" ]]; then
  printf 'PR #%s is not merged (state=%s). Cleanup stopped.\n' "$pr_number" "$pr_state"
  exit 2
fi

if [[ "$head_branch" == "main" || "$head_branch" == "master" || "$head_branch" == "$base_branch" ]]; then
  die "Refusing cleanup for protected/base branch '$head_branch'"
fi

current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ "$current_branch" == "$head_branch" ]]; then
  log "Current branch is PR head '$head_branch'; switching to '$target_branch'"
  ensure_branch_checked_out "$target_branch"
fi

same_repo=0
if [[ -n "$head_owner" && -n "$head_repo" ]]; then
  current_repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
  head_repo_full="${head_owner}/${head_repo}"
  if [[ -n "$current_repo" && "$current_repo" == "$head_repo_full" ]]; then
    same_repo=1
  fi
fi

remote_deleted="skipped"
if [[ "$same_repo" -eq 1 ]]; then
  if git ls-remote --exit-code --heads origin "$head_branch" >/dev/null 2>&1; then
    log "Deleting remote branch origin/$head_branch"
    git push origin --delete "$head_branch"
    remote_deleted="yes"
  else
    log "Remote branch origin/$head_branch already absent"
    remote_deleted="already-absent"
  fi
else
  log "PR head branch is from a fork or unknown repository; skipping remote delete"
fi

log "Pruning remote-tracking refs"
git fetch origin --prune

git remote prune origin >/dev/null 2>&1 || true

remove_head_worktrees "$head_branch" "$repo_root"

local_deleted="absent"
if git show-ref --verify --quiet "refs/heads/$head_branch"; then
  log "Deleting local branch $head_branch"
  if git branch -d "$head_branch" >/dev/null 2>&1; then
    local_deleted="yes"
  else
    warn "Safe delete failed for '$head_branch'; attempting force delete after merge verification"
    if git branch -D "$head_branch" >/dev/null 2>&1; then
      local_deleted="forced"
    else
      warn "Could not delete local branch '$head_branch' (likely still used by a worktree)"
      local_deleted="failed"
    fi
  fi
fi

log "Switching to $target_branch"
ensure_branch_checked_out "$target_branch"

log "Pulling latest origin/$target_branch with --ff-only"
git pull --ff-only origin "$target_branch"

final_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"

printf '\nCleanup summary:\n'
printf '  PR: #%s (%s)\n' "$pr_number" "$pr_state"
printf '  Head branch: %s\n' "$head_branch"
printf '  Remote branch deletion: %s\n' "$remote_deleted"
printf '  Local branch deletion: %s\n' "$local_deleted"
printf '  Final branch: %s\n' "$final_branch"
