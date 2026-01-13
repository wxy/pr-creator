---
name: pr-creator
description: A minimal, dependency-light skill to create PRs with semantic versioning support, structured descriptions, and automatic branch renaming.
---

# PR Creator Skill

This skill automates PR creation with AI-guided semantic versioning and branch renaming.

## Installation

### Using OpenSkills (Remote Install)

```bash
# Install latest skill from remote repository
openskills install wxy/pr-creator -y

# Sync to AGENTS.md for conversation usage
openskills sync -y
```

### Manual Installation

Clone this repository to your local skills directory or use the script directly.

## Usage

### With OpenSkills (Recommended)

After installation and sync, simply trigger the skill in conversation:

**Trigger phrases**:
- "创建 PR" (Chinese)
- "Create a PR" (English)
- "Suggest version bump"
- "Update version and open PR"

The AI will automatically invoke this skill to help you create or update PRs.

### Direct Script Execution

```bash
# If installed via OpenSkills
bash .claude/skills/pr-creator/scripts/create-pr.sh

# Or from the repository
bash skills/pr-creator/scripts/create-pr.sh
```

### Conversation Language & Localization

The skill automatically detects conversation language and generates PR content in the appropriate language:
- **Chinese** (`PR_LANG=zh`): PR description in Chinese
- **English** (default): PR description in English

When invoked from OpenSkills, the AI assistant will generate all PR content in the conversation language.

## Capabilities

- Analyze commits and detect change types (BREAKING/`!`, `feat`, `fix`, `refactor`, etc.)
- Suggest a semantic version bump based on commits
- Auto-detect version files (manifest.json, package.json, pyproject.toml, setup.py)
- **AI-generated PR titles and descriptions** (no templates needed)
- Automatic language detection for content generation
- **Check for existing PR** and update instead of creating duplicates
- Create or update PR via `gh` CLI (zero dependencies beyond git + gh)

## Workflow

The PR creation is split into two phases for optimal AI decision-making:

### Phase 1: Analyze (`create-pr-analyze.sh`)

1. **Check for existing PR** on current branch
2. **Analyze commits** since `origin/master`
   - Detect change types (BREAKING, feat, fix, etc.)
   - Suggest semantic version bump
3. **Output analysis** in key=value format
   - Current branch, version, proposed version
   - Recent commit messages
   - Suggested version bump level

### Phase 2: Apply (`create-pr-apply.sh`)

Applies AI-generated decisions to create/update PR:

1. **Validate inputs** - Check for required AI variables
2. **Update version** (if not skipped)
   - Detect and update version file (manifest.json, package.json, pyproject.toml, setup.py)
   - Create commit and push
3. **Create or update PR** via `gh` CLI
   - If PR exists on branch → update body
   - Otherwise → create new PR with title and body
4. **Clean up** - Remove temporary files

### Wrapper Script (`create-pr.sh` - backward compatible)

Orchestrates both phases:

1. Run analyze phase
2. Either:
   - Use AI-provided decisions (PR_TITLE_AI, PR_BODY_AI, VERSION_BUMP_AI)
   - Or prompt user for confirmation
3. Run apply phase with final decisions

## AI Integration

The skill is now split into two phases for optimal AI decision-making:

**Phase 1: Analyze** (`create-pr-analyze.sh`)
```bash
bash create-pr-analyze.sh
# Outputs: branch, version, suggested bump, recent commits
# AI reads this to understand what changes are being proposed
```

**Phase 2: Apply** (`create-pr-apply.sh`)
```bash
PR_TITLE_AI="Your title" \
PR_BODY_AI="Your body" \
VERSION_BUMP_AI="minor" \
NEW_VERSION="1.5.0" \
bash create-pr-apply.sh
# Uses AI decisions to create/update PR with zero interaction
```

**Unified Workflow** (`create-pr.sh` - backward compatible)
```bash
# Interactive mode
bash create-pr.sh
# Prompts user for decisions

# Autonomous AI mode (set environment variables first)
PR_TITLE_AI="..." PR_BODY_AI="..." VERSION_BUMP_AI="minor" bash create-pr.sh
```

### Usage from OpenSkills

When invoked from conversation, the AI assistant will:
1. Run `create-pr-analyze.sh` to gather PR analysis
2. Analyze commits and generate optimal PR title and body
3. Determine appropriate version bump (major/minor/patch/skip)
4. Run `create-pr-apply.sh` with AI-generated decisions
5. Report success to user

## Installation & Version Control

- Installed skills are placed under `.claude/skills/` as installation artifacts; do not commit them to git
- The repository includes `.gitignore` rules to exclude `.claude/`
- For universal/shared installs, skills use `.agent/skills/` directory
- Source of truth: remote repository `wxy/pr-creator`
- To update locally: `openskills install wxy/pr-creator -y && openskills sync -y`

## Implementation Notes

- Uses POSIX shell script (`scripts/create-pr.sh`) with `git` and `gh` CLI
- No external dependencies beyond shell basics and GitHub CLI
- Cross-platform compatible (macOS, Linux)
- Supports environment variable overrides (`PR_LANG`, `--lang` flag)
