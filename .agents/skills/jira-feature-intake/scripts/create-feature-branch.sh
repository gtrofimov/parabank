#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

issue_key="${1:-}"
slug="${2:-}"
[[ -n "$issue_key" && -n "$slug" ]] || {
    echo "Usage: $0 <ISSUE-KEY> <short-slug>" >&2
    exit 2
}

slug=$(printf '%s' "$slug" | tr '[:upper:] ' '[:lower:]-' | tr -cs 'a-z0-9-' '-')
branch="feature/${issue_key}-${slug}"

[[ -z "$(git status --porcelain)" ]] || {
    echo "Working tree is not clean; commit or stash changes first" >&2
    exit 2
}

git fetch origin master
git checkout master
git merge --ff-only origin/master

if git show-ref --verify --quiet "refs/heads/$branch"; then
    current_base=$(git merge-base master "$branch")
    master_head=$(git rev-parse master)
    [[ "$current_base" == "$master_head" ]] || {
        echo "Branch $branch exists and has diverged from master" >&2
        exit 2
    }
    git checkout "$branch"
else
    git checkout -b "$branch" master
fi

printf 'Feature branch ready: %s\n' "$branch"
