#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

count="${1:-${PULL_SHARK_COUNT:-1}}"
delay="${PULL_SHARK_DELAY:-10}"
log="achievements/pull-shark-log.md"

if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]]; then
  echo "Usage: ./scripts/pull-shark.sh [count]" >&2
  echo "  or:  PULL_SHARK_COUNT=11 ./scripts/pull-shark.sh" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is dirty. Commit or stash changes first." >&2
  exit 1
fi

git checkout main
git pull --ff-only origin main

mkdir -p achievements
if [[ ! -f "$log" ]]; then
  cat > "$log" <<'EOF'
# Pull Shark log

Merged pull requests created for the Pull Shark achievement tiers.

EOF
  git add "$log"
  git commit -m "Start Pull Shark merge log"
  git push origin main
  git pull --ff-only origin main
fi

for ((i = 1; i <= count; i++)); do
  branch="pull-shark-$(date +%Y%m%d%H%M%S)-$i"
  git checkout main
  git pull --ff-only origin main
  git checkout -b "$branch"

  {
    echo
    echo "- $(date -u +"%Y-%m-%dT%H:%M:%SZ") — run $i/$count on branch \`$branch\`"
  } >> "$log"

  git add "$log"
  git commit -m "Pull Shark run $i/$count"
  git push -u origin "$branch"

  pr_url="$(gh pr create \
    --title "Pull Shark run $i/$count" \
    --body "Achievement progress toward Pull Shark bronze (16 merged PRs)." \
    --base main \
    --head "$branch")"

  pr_number="${pr_url##*/}"
  sleep "$delay"
  gh pr merge "$pr_number" --merge --delete-branch
  echo "Merged $pr_url"

  git checkout main
  git pull --ff-only origin main

  if [[ "$i" -lt "$count" ]]; then
    echo "Waiting ${delay}s before next merge..."
    sleep "$delay"
  fi
done

echo "Pull Shark batch complete: $count merged pull request(s)."
