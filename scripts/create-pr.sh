#!/usr/bin/env bash
set -euo pipefail

# PR Creator: Automate PR creation with semantic versioning and branch management
# Dependencies: git, gh, sed

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
err()  { printf "[ERROR] %s\n" "$1"; }

current_branch() { git rev-parse --abbrev-ref HEAD; }

check_existing_pr() {
  local branch="$1"
  gh pr list --head "$branch" --json number --jq '.[0].number' 2>/dev/null || echo ""
}

latest_version_from_manifest() {
  if [[ -f manifest.json ]]; then
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' manifest.json | head -1
  else
    echo "" 
  fi
}

suggest_bump() {
  local log; log=$(git log origin/master..HEAD --format="%s" || true)
  
  # Major: breaking changes
  if echo "$log" | grep -Eiq '(BREAKING CHANGE|!:)'; then 
    echo major
    return
  fi
  
  # Count feat commits
  local feat_count
  feat_count=$(echo "$log" | grep -Eic '^feat:' || echo 0)
  
  # Minor: 2+ feat commits (likely multiple user-facing features)
  if [[ "$feat_count" -ge 2 ]]; then
    echo minor
    return
  fi
  
  # Patch: single feat (likely UI tweak/internal improvement), fix, refactor, docs, etc.
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
  sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"${from}\"/\"version\": \"${to}\"/" manifest.json
  rm -f manifest.json.bak
}

slugify() {
  echo "$1" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# 1) Check for existing PR
bold "Checking for existing PR..."
CBR="$(current_branch)"
EXISTING_PR="$(check_existing_pr "$CBR")"
if [[ -n "$EXISTING_PR" ]]; then
  info "Found existing PR #$EXISTING_PR on branch $CBR"
  PR_MODE="update"
else
  info "No existing PR found; will create new PR"
  PR_MODE="create"
fi

# 2) Analyze
bold "Analyzing commits and current version..."
VER="$(latest_version_from_manifest)"
[[ -z "$VER" ]] && VER="0.1.0" && warn "No version found in manifest.json; defaulting to $VER"
info "Current branch: $CBR"
info "Current version: $VER"

SUG="$(suggest_bump)"

# Provide context for the suggestion
echo
bold "Version bump analysis"
COMMIT_LOG=$(git log origin/master..HEAD --format="  - %s" || echo "  (no commits)")
echo "Recent commits:"
echo "$COMMIT_LOG"
echo
info "Suggested bump: $SUG"

# Explain the reasoning
case "$SUG" in
  major)
    info "Reason: Breaking changes detected (BREAKING CHANGE or !:)";;
  minor)
    info "Reason: Multiple new features detected (2+ feat: commits)";;
  patch)
    info "Reason: Bug fixes, single feature, or improvements";;
esac

NEWVER="$(bump_version "$VER" "$SUG")"; info "Proposed version: $VER → $NEWVER"

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
# Parse optional language flag from CLI
PR_LANG_ARG=""
for arg in "$@"; do
  case "$arg" in
    --lang=*) PR_LANG_ARG="${arg#*=}" ; shift ;;
    --lang)   shift; PR_LANG_ARG="${1:-}" ; shift ;;
    -l)       PR_LANG_ARG="${1:-}" ; shift ;;
  esac
done


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

# 5) Generate PR description - use templates from references/
# Temporary file stored in .github but NOT committed to git
mkdir -p .github
PR_TEMP_FILE=".github/.pr_description_tmp.md"

# Detect language from explicit env var first, then system locale
detect_language() {
  local lang
  # Priority: explicit CLI arg > env PR_LANG > LC_ALL/LC_MESSAGES > LANG
  if [[ -n "$PR_LANG_ARG" ]]; then
    lang="$PR_LANG_ARG"
  else
    lang="${PR_LANG:-}"
  fi
  if [[ -z "$lang" ]]; then
    lang="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  fi
  if echo "$lang" | grep -Eiq 'zh|zh_CN|zh-CN|Chinese|中文'; then
    echo zh
  else
    echo en
  fi
}

PR_LANG_DETECTED="$(detect_language)"
if [[ "$PR_LANG_DETECTED" == "zh" ]]; then
  PR_TEMPLATE="references/pull_request_template_zh.md"
else
  PR_TEMPLATE="references/pull_request_template.md"
fi

# Always fallback to English template if language-specific template doesn't exist
if [[ ! -f "$PR_TEMPLATE" ]]; then
  warn "Template $PR_TEMPLATE not found, using English template as fallback"
  PR_TEMPLATE="references/pull_request_template.md"
fi
info "Using PR template: $PR_TEMPLATE (lang=$PR_LANG_DETECTED)"

if [[ -f "$PR_TEMPLATE" ]]; then
  cp "$PR_TEMPLATE" "$PR_TEMP_FILE"
else
  cat > "$PR_TEMP_FILE" <<'EOF'
# PR Summary

## Overview
Brief description of the purpose and impact of this PR.

## Changes
- Key changes listed here

## Versioning
- Version information

## Testing
- [ ] Tests completed

## Checklist
- [ ] Ready for review
EOF
fi

# Localize dynamic bump label for template content
localized_bump() {
  local level="$1" lang="$2"
  case "$lang" in
    zh)
      case "$level" in
        major) echo "主版本";;
        minor) echo "次版本";;
        patch) echo "修订";;
        *) echo "$level";;
      esac
      ;;
    *)
      echo "$level"
      ;;
  esac
}
L10N_SUG="$(localized_bump "$SUG" "$PR_LANG_DETECTED")"

# Insert actual values
sed -i.bak \
  -e "s|Brief description.*|${PR_TITLE}|" \
  -e "s|简要描述.*|${PR_TITLE}|" \
  -e "s|X\.Y\.Z|${VER}|g" \
  -e "s|A\.B\.C|${FINAL_VER}|g" \
  -e "s|major/minor/patch|${L10N_SUG}|g" \
  "$PR_TEMP_FILE"
rm -f "${PR_TEMP_FILE}.bak"

# 6) Create or Update PR via gh
if [[ "$PR_MODE" == "update" ]]; then
  bold "Updating PR #$EXISTING_PR..."
  gh pr edit "$EXISTING_PR" --body-file "$PR_TEMP_FILE" || { err "gh pr edit failed"; exit 1; }
  info "PR #$EXISTING_PR updated successfully"
else
  bold "Creating PR via gh..."
  GH_ARGS=(--title "$PR_TITLE" --body-file "$PR_TEMP_FILE" --base master)
  gh pr create "${GH_ARGS[@]}" || { err "gh pr create failed"; exit 1; }
  info "PR created successfully"
fi

rm -f "$PR_TEMP_FILE"
