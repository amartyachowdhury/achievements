#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

branch="yolo-$(date +%Y%m%d%H%M%S)"
marker="achievements/yolo.md"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is dirty. Commit or stash changes first." >&2
  exit 1
fi

git checkout main
git pull --ff-only origin main

git checkout -b "$branch"
mkdir -p achievements
cat > "$marker" <<EOF
# YOLO

Earned by merging pull request without code review.

- Branch: \`$branch\`
- Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

git add "$marker"
git commit -m "Add YOLO achievement marker"
git push -u origin "$branch"

pr_url="$(gh pr create \
  --title "YOLO: merge without review" \
  --body "Achievement run for the YOLO badge." \
  --base main \
  --head "$branch")"

pr_number="${pr_url##*/}"
gh pr merge "$pr_number" --merge --delete-branch

git checkout main
git pull --ff-only origin main

echo "YOLO run complete."
echo "Pull request: $pr_url"
