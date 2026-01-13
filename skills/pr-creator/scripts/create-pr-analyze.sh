#!/usr/bin/env bash
set -euo pipefail

# PR Creator - Analyze: Collect information about PR and commits for AI decision-making
# Dependencies: git, gh
# Output: Structured analysis data in key=value format
# Usage: bash create-pr-analyze.sh > analysis.txt

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
  # Try multiple version file formats in order of priority
  
  # 1. Check manifest.json (standard for this skill)
  if [[ -f manifest.json ]]; then
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' manifest.json | head -1
    return 0
  fi
  
  # 2. Check package.json (Node.js/Plasmo projects)
  if [[ -f package.json ]]; then
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' package.json | head -1
    return 0
  fi
  
  # 3. Check pyproject.toml (Python projects)
  if [[ -f pyproject.toml ]]; then
    grep -E '^version = "([0-9]+\.[0-9]+\.[0-9]+)"' pyproject.toml | sed 's/version = "\([0-9]*\.[0-9]*\.[0-9]*\)"/\1/'
    return 0
  fi
  
  # 4. Check setup.py (Python projects)
  if [[ -f setup.py ]]; then
    grep -oE 'version\s*=\s*["\x27]([0-9]+\.[0-9]+\.[0-9]+)["\x27]' setup.py | sed 's/.*"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/' | head -1
    return 0
  fi
  
  # No version file found
  return 1
}

detect_version_file() {
  [[ -f manifest.json ]] && echo "manifest.json" && return 0
  [[ -f package.json ]] && echo "package.json" && return 0
  [[ -f pyproject.toml ]] && echo "pyproject.toml" && return 0
  [[ -f setup.py ]] && echo "setup.py" && return 0
  echo ""
  return 1
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

# === MAIN ANALYSIS ===
bold "PR Creator - Analysis Phase"
info "Collecting information for AI decision-making..."

CBR="$(current_branch)"
EXISTING_PR="$(check_existing_pr "$CBR")"

if [[ -n "$EXISTING_PR" ]]; then
  PR_MODE="update"
else
  PR_MODE="create"
fi

# Get version info
VER="$(latest_version_from_manifest)"
VERSION_FILE="$(detect_version_file)"

if [[ -z "$VER" ]]; then
  VER="0.1.0"
  VERSION_FILE_MISSING="true"
else
  VERSION_FILE_MISSING="false"
fi

SUG="$(suggest_bump)"
NEWVER="$(bump_version "$VER" "$SUG")"

# Get commits
COMMITS=$(git log origin/master..HEAD --format="%s" | head -20)
COMMITS_JSON=$(git log origin/master..HEAD --format="%s" | jq -R -s -c 'split("\n")[:-1]')

# Output analysis in key=value format (easily parseable by AI)
cat <<EOF
# PR Creator Analysis Output
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

CURRENT_BRANCH=$CBR
EXISTING_PR=$EXISTING_PR
PR_MODE=$PR_MODE

CURRENT_VERSION=$VER
VERSION_FILE=$VERSION_FILE
VERSION_FILE_MISSING=$VERSION_FILE_MISSING

SUGGESTED_BUMP=$SUG
PROPOSED_VERSION=$NEWVER

EOF

# List commits
echo "# Recent commits"
git log origin/master..HEAD --format="# - %s" | head -20

info "Analysis complete. Output above in key=value format for AI processing."
