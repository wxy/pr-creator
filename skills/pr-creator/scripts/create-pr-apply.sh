#!/usr/bin/env bash
set -euo pipefail

# PR Creator - Apply: Use AI-generated decisions to create/update PR
# Dependencies: git, gh, sed
# 
# Required environment variables (from AI):
#   PR_BRANCH          - Branch name to work with
#   PR_TITLE_AI        - AI-generated PR title
#   PR_BODY_AI         - AI-generated PR body (full description)
#   VERSION_BUMP_AI    - AI's version decision (major/minor/patch/skip)
#   CURRENT_VERSION    - Current version from analysis
#   NEW_VERSION        - Target version (AI should calculate this)
#   VERSION_FILE       - Which file contains version (manifest.json, package.json, etc.)
#   PR_LANG            - Language for template selection (zh/en)
#
# Usage: PR_TITLE_AI="..." PR_BODY_AI="..." bash create-pr-apply.sh

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
err()  { printf "[ERROR] %s\n" "$1"; }

current_branch() { git rev-parse --abbrev-ref HEAD; }

check_existing_pr() {
  local branch="$1"
  gh pr list --head "$branch" --json number --jq '.[0].number' 2>/dev/null || echo ""
}

apply_version_bump() {
  local from="$1" to="$2" file="$3"
  
  if [[ ! -f "$file" ]]; then
    warn "Version file $file not found; skipping version update"
    return 1
  fi
  
  case "$file" in
    manifest.json|package.json)
      sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"${from}\"/\"version\": \"${to}\"/" "$file"
      ;;
    pyproject.toml)
      sed -i.bak "s/^version = \"${from}\"/version = \"${to}\"/" "$file"
      ;;
    setup.py)
      sed -i.bak "s/version='${from}'/version='${to}'/" "$file"
      sed -i.bak "s/version=\"${from}\"/version=\"${to}\"/" "$file"
      ;;
    *)
      err "Unknown version file format: $file"
      return 1
      ;;
  esac
  
  rm -f "${file}.bak"
  git add "$file"
  return 0
}

# === INPUT VALIDATION ===
bold "PR Creator - Apply Phase"

# Check required environment variables
for var in PR_TITLE_AI PR_BODY_AI VERSION_BUMP_AI PR_BRANCH; do
  if [[ -z "${!var:-}" ]]; then
    err "Missing required variable: $var"
    exit 1
  fi
done

PR_TITLE="${PR_TITLE_AI}"
PR_BODY="${PR_BODY_AI}"
FINAL_LEVEL="${VERSION_BUMP_AI}"
WORKING_BRANCH="${PR_BRANCH}"

# Optional variables with defaults
CURRENT_VER="${CURRENT_VERSION:-}"
NEW_VER="${NEW_VERSION:-}"
VERSION_FILE="${VERSION_FILE:-}"
PR_LANG="${PR_LANG:-en}"

info "PR Title: $PR_TITLE"
info "Branch: $WORKING_BRANCH"
info "Version: $CURRENT_VER → $NEW_VER"
info "Bump level: $FINAL_LEVEL"

# === CHANGE TO BRANCH ===
git checkout "$WORKING_BRANCH" 2>/dev/null || {
  err "Failed to checkout branch: $WORKING_BRANCH"
  exit 1
}

# === VERSION UPDATE ===
if [[ "$FINAL_LEVEL" != "skip" ]] && [[ -n "$CURRENT_VER" ]] && [[ -n "$NEW_VER" ]] && [[ -n "$VERSION_FILE" ]]; then
  bold "Updating version ($CURRENT_VER → $NEW_VER)"
  if apply_version_bump "$CURRENT_VER" "$NEW_VER" "$VERSION_FILE"; then
    git commit -m "chore: version bump ${CURRENT_VER} → ${NEW_VER}" || info "No version changes to commit"
    git push origin "$(current_branch)" || true
    info "Version updated and pushed"
  else
    warn "Version update failed; continuing with PR creation"
  fi
else
  if [[ "$FINAL_LEVEL" == "skip" ]]; then
    info "Skipping version update (as requested)"
  else
    info "Missing version info; skipping version update"
  fi
fi

# === CREATE/UPDATE PR ===
bold "Creating/updating PR"

# Prepare temporary PR body file
mkdir -p .github
PR_TEMP_FILE=".github/.pr_body_from_ai.md"

# Write AI-generated body to file
cat > "$PR_TEMP_FILE" <<'EOF'
$PR_BODY
EOF

# Check for existing PR
CBR="$(current_branch)"
EXISTING_PR="$(check_existing_pr "$CBR")"

if [[ -n "$EXISTING_PR" ]]; then
  bold "Updating PR #$EXISTING_PR..."
  gh pr edit "$EXISTING_PR" --body-file "$PR_TEMP_FILE" || {
    err "Failed to update PR"
    exit 1
  }
  info "PR #$EXISTING_PR updated successfully"
else
  bold "Creating new PR..."
  gh pr create --title "$PR_TITLE" --body-file "$PR_TEMP_FILE" --base master || {
    err "Failed to create PR"
    exit 1
  }
  info "PR created successfully"
fi

# Cleanup
rm -f "$PR_TEMP_FILE"

info "Done!"
