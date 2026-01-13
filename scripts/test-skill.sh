#!/bin/bash
set -euo pipefail

# PR Creator - Test Mode Script
# This script helps you test the skill locally before pushing to repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills/pr-creator"

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
info() { printf "[INFO] %s\n" "$1"; }
success() { printf "\033[32m[✓]\033[0m %s\n" "$1"; }
warn() { printf "\033[33m[!]\033[0m %s\n" "$1"; }

bold "🧪 PR Creator - Test Mode Setup"
echo ""

# Check if OpenSkills is installed
if ! command -v openskills &> /dev/null; then
  warn "OpenSkills not found. This script helps test the skill before installing."
fi

# Step 1: Backup existing installation (if any)
if [[ -d "$CLAUDE_SKILLS_DIR" ]]; then
  BACKUP_DIR="${CLAUDE_SKILLS_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
  info "Backing up existing installation to: $BACKUP_DIR"
  cp -r "$CLAUDE_SKILLS_DIR" "$BACKUP_DIR"
  success "Backup created"
fi

# Step 2: Create/Update test installation
info "Installing current development version..."
mkdir -p "$CLAUDE_SKILLS_DIR"

# Copy skill files
cp -r "$PROJECT_ROOT/skills/pr-creator/scripts" "$CLAUDE_SKILLS_DIR/"
cp "$PROJECT_ROOT/skills/pr-creator/SKILL.md" "$CLAUDE_SKILLS_DIR/"

success "Development version installed to: $CLAUDE_SKILLS_DIR"

# Step 3: Show usage
echo ""
bold "📝 How to Test"
echo ""
echo "1. In your AI conversation, say: '创建 PR' or 'Create a PR'"
echo "   The AI will use the development version you just installed."
echo ""
echo "2. Or test with DRY_RUN mode:"
echo "   DRY_RUN=true PR_BRANCH=\"...\" PR_TITLE_AI=\"...\" \\"
echo "   bash $CLAUDE_SKILLS_DIR/scripts/create-pr.sh"
echo ""
echo "3. To restore original version:"
if [[ -d "${CLAUDE_SKILLS_DIR}.backup."* ]]; then
  LATEST_BACKUP=$(ls -d "${CLAUDE_SKILLS_DIR}.backup."* | tail -1)
  echo "   rm -rf $CLAUDE_SKILLS_DIR"
  echo "   mv $LATEST_BACKUP $CLAUDE_SKILLS_DIR"
else
  echo "   openskills sync -y"
fi
echo ""

success "Test setup complete!"
