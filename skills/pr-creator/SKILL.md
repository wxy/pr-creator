---
name: pr-creator
description: AI-native skill to automate PR creation with semantic versioning and intelligent descriptions.
---

# PR Creator Skill

A minimal, intelligent skill that creates or updates pull requests with AI-generated titles, descriptions, and semantic versioning.

## Installation

### Using OpenSkills (Recommended)

```bash
openskills install wxy/pr-creator -y
openskills sync -y
```

### Manual Installation

Clone this repository to your local skills directory or use the script directly.

## How It Works

This is an **AI-first skill**. The AI assistant orchestrates the workflow:

1. **Analyze** (AI does this internally):
   - Run `git log` to get commits
   - Detect commit types (feat, fix, BREAKING, etc.)
   - Identify version file and current version
   - Suggest semantic version bump

2. **Generate** (AI does this):
   - Create PR title from commit message or branch name
   - Write comprehensive PR description
   - Calculate new version number
   - Determine bump level (major/minor/patch/skip)

3. **Execute** (AI assistants should use create_file):
   
   **Method A - create_file tool (BEST for AI assistants)**:
   ```python
   # AI should use create_file tool - most reliable
   create_file(
     filePath=".github/pr-description.tmp",
     content="""## 功能说明
这个 PR 实现了...

## 改动
- 功能 1"""
   )
   
   # Then execute with env vars
   run_in_terminal(
     command="bash create-pr.sh",
     env={
       "PR_BRANCH": "feat/my-feature",
       "PR_TITLE_AI": "feat: 新增功能",
       "PR_LANG": "zh-CN",
       "VERSION_BUMP_AI": "minor",
       ...
     }
   )
   ```

   **Why create_file for AI?** No shell issues, reliable in AI environments

   **Method B - printf (for manual terminal use)**:
   ```bash
   # When humans execute in terminal
   mkdir -p .github
   printf '%s\n' \
     "## 功能说明" \
     "..." > .github/pr-description.tmp
   
   PR_BRANCH="feat/my-feature" \
   PR_TITLE_AI="feat: 新增功能" \
   PR_LANG="zh-CN" \
   bash create-pr.sh
   ```

   **Method C - Environment Variable (short content)**:
   ```bash
   PR_BRANCH="feat/my-feature" \
   PR_TITLE_AI="feat: 新增功能" \
   PR_BODY_AI="简短的 PR 描述" \
   PR_LANG="zh-CN" \
   VERSION_BUMP_AI="minor" \
   ... bash create-pr.sh
   ```

   **Method D - Stdin (dynamic content)**:
   ```bash
   echo "PR description" | \
   PR_BRANCH="feat/my-feature" \
   PR_TITLE_AI="feat: 新增功能" \
   PR_LANG="zh-CN" \
   VERSION_BUMP_AI="minor" \
   ... bash create-pr.sh
   ```

   **Important**: Always set `PR_LANG` to match your conversation language!

## Usage

### From OpenSkills (Recommended)

Simply tell the AI in conversation:
- "创建 PR" (Chinese)
- "Create a PR" (English)
- "Create PR for this feature"
- "Open a pull request"

The AI will automatically invoke this skill to:
1. Analyze your branch and commits
2. Generate optimal PR title and description
3. Determine semantic version bump
4. Create/update the PR
5. Report success

### Direct Script Execution

```bash
# Set all decisions, then run
PR_BRANCH="$(git rev-parse --abbrev-ref HEAD)" \
PR_TITLE_AI="feat: my feature" \
PR_BODY_AI="..." \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="package.json" \
bash skills/pr-creator/scripts/create-pr.sh
```

## Capabilities

✅ **Commit Analysis**
- Detects BREAKING CHANGE → major version
- Counts `feat:` commits → minor version  
- Single feature/fix → patch version

✅ **Multi-Project Support**
- manifest.json (standard)
- package.json (Node.js/Plasmo)
- pyproject.toml (Python)
- setup.py (Python)

✅ **Smart PR Management**
- Detects existing PR on branch
- Updates instead of creating duplicates
- Creates new PR if none exists

✅ **Pure AI Decisions**
- No templates, no placeholders
- AI generates complete, contextual descriptions
- Supports any language (via AI generation + PR_LANG variable)
- Long descriptions can be written to `.github/pr-description.tmp`
- No user interaction required

✅ **Language Awareness**
- PR title and body follow conversation language
- Use `PR_LANG` environment variable to control (e.g., zh-CN, en)
- Ensures consistency across PR in your preferred language

## Workflow (AI Perspective)

```
User: "Create a PR"
  ↓
AI: Analyze branch
  - git log origin/master..HEAD
  - Detect version file and version
  - Analyze commit types
  ↓
AI: Generate decisions
  - PR_TITLE_AI from latest commit
  - PR_BODY_AI with detailed description
  - VERSION_BUMP_AI based on commits
  ↓
AI: Execute script
  bash create-pr.sh (with all env vars)
  ↓
Script: Apply changes
  1. Update version file (if bump != skip)
  2. Create/update PR via gh CLI
  3. Report success
  ↓
Done! PR created/updated
```

## Environment Variables

Required for script execution:

| Variable | Purpose | Example |
|----------|---------|---------|
| `PR_BRANCH` | Current branch | `feat/new-feature` |
| `PR_TITLE_AI` | PR title (respects PR_LANG) | `feat: add auth` |
| `PR_BODY_AI` | PR description | `## Overview...` |
| `VERSION_BUMP_AI` | Version action | `minor`, `patch`, `skip` |
| `CURRENT_VERSION` | Before version | `1.0.0` |
| `NEW_VERSION` | After version | `1.1.0` |
| `VERSION_FILE` | Version location | `package.json` |
| `PR_LANG` *(optional)* | PR language | `zh-CN`, `en` |

**Note**: For long PR descriptions, create `.github/pr-description.tmp` instead of passing via `PR_BODY_AI` - the script automatically reads it if present.

## Technical Details

- **Language**: POSIX shell script
- **Dependencies**: `git`, `gh` (GitHub CLI)
- **Platforms**: macOS, Linux
- **Size**: ~150 lines
- **Philosophy**: Minimal, focused, AI-native

## Why This Design?

### Problems Solved

1. **No template maintenance** 
   - Previous versions used templates
   - Templates become outdated, inflexible
   - AI generates better descriptions anyway

2. **No redundant scripts**
   - Single `create-pr.sh` entry point
   - AI calls it with all decisions
   - No wrapper layers

3. **Pure AI orchestration**
   - Script = execution engine only
   - AI = decision maker
   - Clear separation of concerns

### Design Principles

- **Minimal**: Only what's necessary
- **Focused**: One job, do it well
- **AI-native**: Built for AI orchestration
- **Explicit**: All decisions visible in env vars
- **Transparent**: Simple shell script, easy to audit

## Future Enhancements

- [ ] Dry-run mode for testing
- [ ] Custom PR template via API
- [ ] Automatic label assignment
- [ ] PR review suggestions
- [ ] Changelog generation
