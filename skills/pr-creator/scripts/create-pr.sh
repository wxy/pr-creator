#!/usr/bin/env bash
set -euo pipefail

# PR Creator: Unified wrapper for backward compatibility
# This script orchestrates the analyze + apply workflow
# Supports multiple modes:
#   1. Autonomous AI mode: analyze → apply with AI decisions
#   2. Interactive mode: analyze → prompt user → apply
#
# For AI usage: set PR_TITLE_AI, PR_BODY_AI, VERSION_BUMP_AI, NEW_VERSION_AI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
err()  { printf "[ERROR] %s\n" "$1"; }

# === PHASE 1: ANALYZE ===
bold "=== Phase 1: Analyze ==="
ANALYSIS=$("$SCRIPT_DIR/create-pr-analyze.sh" 2>/dev/null | grep -v "^\[")

# Parse analysis output
eval "$ANALYSIS"

info "Current branch: $CURRENT_BRANCH"
info "Current version: $CURRENT_VERSION"
info "Suggested bump: $SUGGESTED_BUMP"
info "Proposed version: $PROPOSED_VERSION"

# === PHASE 2: AI DECISION OR USER INTERACTION ===
if [[ -n "${PR_TITLE_AI:-}" ]] && [[ -n "${VERSION_BUMP_AI:-}" ]]; then
  # AI mode: use pre-provided decisions
  bold "=== Phase 2: Using AI Decisions ==="
  info "PR Title: $PR_TITLE_AI"
  info "Version Bump: $VERSION_BUMP_AI"
  FINAL_TITLE="$PR_TITLE_AI"
  FINAL_VERSION_BUMP="$VERSION_BUMP_AI"
  
  # Calculate new version
  if [[ -n "${NEW_VERSION_AI:-}" ]]; then
    NEW_VER="$NEW_VERSION_AI"
  elif [[ "$FINAL_VERSION_BUMP" == "skip" ]]; then
    NEW_VER="$CURRENT_VERSION"
  else
    IFS='.' read -r MA MI PA <<<"$CURRENT_VERSION"
    case "$FINAL_VERSION_BUMP" in
      major) ((MA=MA+1)); MI=0; PA=0;;
      minor) ((MI=MI+1)); PA=0;;
      patch) ((PA=PA+1));;
      *) NEW_VER="$CURRENT_VERSION";;
    esac
    NEW_VER="${MA}.${MI}.${PA}"
  fi
else
  # Interactive mode
  bold "=== Phase 2: User Confirmation ==="
  
  echo
  echo "Recent commits:"
  git log origin/master..HEAD --format="  - %s" 2>/dev/null | head -10
  
  echo
  echo "Version Decision:"
  echo "  Current: $CURRENT_VERSION"
  echo "  Suggested bump: $SUGGESTED_BUMP"
  echo "  Would result in: $PROPOSED_VERSION"
  echo
  
  read -r -p "Confirm $SUGGESTED_BUMP bump? [Y/n/s(skip)]: " choice
  choice=${choice:-y}
  
  case "$choice" in
    Y|y)
      FINAL_VERSION_BUMP="$SUGGESTED_BUMP"
      NEW_VER="$PROPOSED_VERSION"
      ;;
    n|N)
      read -r -p "Enter level [major/minor/patch]: " level
      FINAL_VERSION_BUMP="$level"
      IFS='.' read -r MA MI PA <<<"$CURRENT_VERSION"
      case "$level" in
        major) ((MA=MA+1)); MI=0; PA=0;;
        minor) ((MI=MI+1)); PA=0;;
        patch) ((PA=PA+1));;
      esac
      NEW_VER="${MA}.${MI}.${PA}"
      ;;
    s|S)
      FINAL_VERSION_BUMP="skip"
      NEW_VER="$CURRENT_VERSION"
      ;;
    *)
      err "Invalid selection"
      exit 1
      ;;
  esac
  
  # Auto-generate PR title
  LATEST_COMMIT=$(git log -1 --format="%s" 2>/dev/null || echo "")
  if [[ -n "$LATEST_COMMIT" ]] && [[ "$LATEST_COMMIT" != "merge"* ]] && [[ "$LATEST_COMMIT" != "Merge"* ]]; then
    FINAL_TITLE="$LATEST_COMMIT"
    info "Title from commit: $FINAL_TITLE"
  else
    BRANCH_NAME=$(echo "$CURRENT_BRANCH" | sed -E 's/[^a-zA-Z0-9]+/ /g; s/^\s+|\s+$//g')
    FINAL_TITLE="$BRANCH_NAME"
    info "Title from branch: $FINAL_TITLE"
  fi
fi

# === PHASE 3: GENERATE PR BODY ===
if [[ -n "${PR_BODY_AI:-}" ]]; then
  # Use AI-provided body
  bold "=== Phase 3: Using AI-Generated PR Body ==="
  FINAL_BODY="$PR_BODY_AI"
else
  # Generate default body
  bold "=== Phase 3: Generating Default PR Body ==="
  FINAL_BODY=$(cat <<EOF
## Summary
$FINAL_TITLE

## Changes
- See commits for details

## Version
- From: $CURRENT_VERSION → To: $NEW_VER
- Bump: $FINAL_VERSION_BUMP

## Checklist
- [ ] Tests completed
- [ ] Ready for review
EOF
)
fi

# === PHASE 4: APPLY ===
bold "=== Phase 4: Apply (Create/Update PR) ==="

PR_TITLE_AI="$FINAL_TITLE" \
PR_BODY_AI="$FINAL_BODY" \
VERSION_BUMP_AI="$FINAL_VERSION_BUMP" \
PR_BRANCH="$CURRENT_BRANCH" \
CURRENT_VERSION="$CURRENT_VERSION" \
NEW_VERSION="$NEW_VER" \
VERSION_FILE="$VERSION_FILE" \
"$SCRIPT_DIR/create-pr-apply.sh"

info "PR creation workflow complete!"
