#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

reviewer="${YOLO_REVIEWER:-}"
if [[ -z "$reviewer" ]]; then
  echo "YOLO_REVIEWER is required." >&2
  echo "Add a second GitHub account as a collaborator, accept the invite, then run:" >&2
  echo "  YOLO_REVIEWER=other-username ./scripts/yolo.sh" >&2
  exit 1
fi

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

Earned by merging a pull request while a review was requested but not completed.

- Branch: \`$branch\`
- Reviewer: \`$reviewer\`
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
gh pr edit "$pr_number" --add-reviewer "$reviewer"
gh pr merge "$pr_number" --merge --delete-branch

git checkout main
git pull --ff-only origin main

echo "YOLO run complete."
echo "Pull request: $pr_url"
echo "Requested review from: $reviewer"
echo "The badge can take a few minutes to appear on your profile."
