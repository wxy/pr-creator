#!/usr/bin/env bash
set -euo pipefail

# Universal PR + Versioning (manifest.json) + Branch rename
# Dependencies: git, gh, sed

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
err()  { printf "[ERROR] %s\n" "$1"; }

current_branch() { git rev-parse --abbrev-ref HEAD; }
latest_version_from_manifest() {
  if [[ -f manifest.json ]]; then
    sed -n 's/.*"version"\s*:\s*"\([0-9]\+\.[0-9]\+\.[0-9]\+\)".*/\1/p' manifest.json | head -1
  else
    echo "" 
  fi
}

suggest_bump() {
  local log; log=$(git log origin/master..HEAD --format="%s" || true)
  if echo "$log" | grep -Eiq '(BREAKING CHANGE|!:)'; then echo major; return; fi
  if echo "$log" | grep -Eiq '^feat:'; then echo minor; return; fi
  echo patch
}

bump_version() {
  local v="$1" level="$2"
  IFS='.' read -r MA MI PA <<<"$v"
  case "$level" in
    major) ((MA=MA+1)); MI=0; PA=0;;
    minor) ((MI=MI+1)); PA=0;;
    patch) ((PA=PA+1));;
    *) err "Unknown bump level: $level"; return 1;;
  esac
  echo "${MA}.${MI}.${PA}"
}

apply_manifest_bump() {
  local from="$1" to="$2"
  if [[ ! -f manifest.json ]]; then
    warn "manifest.json not found; skipping version update"
    return 0
  fi
  sed -i.bak "s/\("version"\s*:\s*\)\"${from}\"/\1\"${to}\"/" manifest.json
  rm -f manifest.json.bak
}

slugify() {
  echo "$1" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# 1) Analyze
bold "Analyzing commits and current version..."
CBR="$(current_branch)"
VER="$(latest_version_from_manifest)"
[[ -z "$VER" ]] && VER="0.1.0" && warn "No version found in manifest.json; defaulting to $VER"
info "Current branch: $CBR"
info "Current version: $VER"

SUG="$(suggest_bump)"; info "Suggested bump: $SUG"
NEWVER="$(bump_version "$VER" "$SUG")"; info "Proposed version: $NEWVER"

echo
bold "Confirm version bump"
echo "A) Accept suggestion ($VER → $NEWVER, $SUG)"
echo "B) Choose another level"
echo "C) Skip version update"
read -r -p "Select [A/B/C]: " CH

case "$CH" in
  A|a)
    FINAL_LEVEL="$SUG"; FINAL_VER="$NEWVER";;
  B|b)
    read -r -p "Level [major/minor/patch]: " LV
    FINAL_LEVEL="$LV"
    FINAL_VER="$(bump_version "$VER" "$LV")";;
  C|c)
    FINAL_LEVEL="skip"; FINAL_VER="$VER";;
  *) err "Invalid choice"; exit 1;;
esac

# 2) Apply bump if not skipped
if [[ "$FINAL_LEVEL" != "skip" ]]; then
  bold "Updating manifest.json version ($VER → $FINAL_VER)"
  apply_manifest_bump "$VER" "$FINAL_VER"
  git add manifest.json || true
  git commit -m "chore: version bump ${VER} → ${FINAL_VER}" || info "No changes to commit"
  git push origin "$(current_branch)" || true
fi

# 3) PR title & description
bold "Prepare PR information"
read -r -p "PR Title: " PR_TITLE
PR_SLUG="$(slugify "$PR_TITLE")"

# 4) Optional branch rename to match PR title
read -r -p "Rename branch to 'pr/${PR_SLUG}'? [y/N]: " RB
if [[ "${RB}" =~ ^[Yy]$ ]]; then
  NEW_BRANCH="pr/${PR_SLUG}"
  git branch -m "$NEW_BRANCH"
  git push origin -u "$NEW_BRANCH"
  # optionally delete old remote
  git push origin --delete "$CBR" 2>/dev/null || true
  CBR="$NEW_BRANCH"
  info "Branch renamed to $CBR"
fi

# 5) Generate PR description
mkdir -p .github
PR_FILE=.github/PR_DESCRIPTION.md
cat > "$PR_FILE" <<EOF
# PR Summary

## Overview
$PR_TITLE

## Changes
- See commit history since origin/master

## Versioning
- Current version: $VER
- Suggested bump: $SUG
- Final decision: $FINAL_VER ($FINAL_LEVEL)

## Testing
- Ensure tests pass (if applicable)

## Impact
- Breaking changes: $(git log origin/master..HEAD --format="%s" | grep -Eiq '(BREAKING CHANGE|!:)' && echo yes || echo no)

## Checklist
- [x] Version updated (if applicable)
- [x] Description present
- [x] Ready for review
EOF

# 6) Create PR via gh
bold "Creating PR via gh..."
GH_ARGS=(--title "$PR_TITLE" --body-file "$PR_FILE" --base master)
# auto-detect head branch
gh pr create "${GH_ARGS[@]}" || { err "gh pr create failed"; exit 1; }
info "PR created successfully"
