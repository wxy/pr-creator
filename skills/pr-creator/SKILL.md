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
   
   **⭐ RECOMMENDED: create_file tool (ONLY reliable method for AI)**:
   ```python
   # AI MUST use create_file tool - this is the ONLY reliable way
   create_file(
     filePath=".github/pr-description.tmp",
     content="""## 功能说明
这个 PR 实现了...

## 改动
- 功能 1"""
   )
   
   # Then execute with env vars and correct path
   run_in_terminal(
     command="bash skills/pr-creator/scripts/create-pr.sh",
     env={
       "PR_BRANCH": "feat/my-feature",
       "PR_TITLE_AI": "feat: 新增功能",
       "PR_LANG": "zh-CN",
       "VERSION_BUMP_AI": "minor",
       "CURRENT_VERSION": "1.0.0",
       "NEW_VERSION": "1.1.0",
       "VERSION_FILE": "manifest.json"
     }
   )
   ```

   **Why create_file is the ONLY option for AI?** 
   - No shell escaping issues
   - No heredoc conflicts
   - Reliable in all environments
   - **Other methods (printf, env var, stdin) are NOT recommended for AI**

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

### For Development (Repository Root)

When working in the repository root directory:

```bash
# Method 1: Using create_file (recommended for AI)
create_file(
  filePath=".github/pr-description.tmp",
  content="Long description here..."
)

run_in_terminal(
  command="bash skills/pr-creator/scripts/create-pr.sh",
  env={...}
)

# Method 2: Direct manual execution
PR_BRANCH="$(git rev-parse --abbrev-ref HEAD)" \
PR_TITLE_AI="feat: my feature" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="package.json" \
bash skills/pr-creator/scripts/create-pr.sh
```

### After Installation via OpenSkills

When skill is installed via OpenSkills (`~/.claude/skills/pr-creator`):

```bash
# Use relative path 'scripts/create-pr.sh' (OpenSkills will cd into skill directory)
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: my feature" \
... \
bash scripts/create-pr.sh
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
  - PR_BODY_AI with detailed description (in memory)
  - VERSION_BUMP_AI based on commits
  ↓
AI: Create PR description file (CRITICAL!)
  create_file(
    filePath=".github/pr-description.tmp",
    content=<AI-generated description>
  )
  ↓
AI: Execute script with FULL PATH
  bash skills/pr-creator/scripts/create-pr.sh (from repo root)
  OR
  bash scripts/create-pr.sh (when already in skill directory)
  ↓
Script: Apply changes
  1. Read .github/pr-description.tmp (created by create_file)
  2. Update version file (if bump != skip)
  3. Create/update PR via gh CLI
  4. Add attribution footer automatically
  5. Report success
  ↓
Done! PR created/updated with proper footer
```

## Environment Variables

Required for script execution:

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `PR_BRANCH` | Current branch | `feat/new-feature` | ✅ Yes |
| `PR_TITLE_AI` | PR title (respects PR_LANG) | `feat: add auth` | ✅ Yes |
| `VERSION_BUMP_AI` | Version action | `minor`, `patch`, `skip` | ✅ Yes |
| `CURRENT_VERSION` | Before version | `1.0.0` | ✅ Yes |
| `NEW_VERSION` | After version | `1.1.0` | ✅ Yes |
| `VERSION_FILE` | Version location | `package.json` | ✅ Yes |
| `PR_LANG` *(optional)* | PR language | `zh-CN`, `en` | ❌ No |
| `DRY_RUN` *(optional)* | Preview without changes | `true`, `false` | ❌ No |
| `.github/pr-description.tmp` | PR body (file) | Created via `create_file` | ✅ Yes (for AI) |
| `PR_BODY_AI` | PR body (env var) | Short text | ⚠️ Only for manual use |

**CRITICAL NOTES**: 
- **For AI assistants**: ALWAYS use `create_file()` to create `.github/pr-description.tmp` - this is the ONLY reliable method
- **For manual terminal use**: Can use `PR_BODY_AI` environment variable (not recommended for AI)
- The script automatically reads from `.github/pr-description.tmp` if it exists
- Set `DRY_RUN=true` to preview PR creation without modifying files or creating PR

### Dry-Run Mode

Test the script without making any changes to your repository:

```bash
# Step 1: Create description file using create_file (ONLY reliable method)
create_file(
  filePath=".github/pr-description.tmp",
  content="## Features\n- Feature 1\n- Feature 2"
)

# Step 2: Run with DRY_RUN=true to preview
DRY_RUN=true \
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: My feature" \
PR_LANG="en" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="package.json" \
bash scripts/pr-creator/scripts/create-pr.sh
```

**Output**: Shows what would happen (version updates, commits, PR creation) without executing

**Perfect for**:
- AI assistants to verify PR decisions before execution
- Testing PR descriptions and titles
- Validating version bumps
- Checking branch names

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

- [x] Dry-run mode for testing
- [ ] Custom PR template via API
- [ ] Automatic label assignment
- [ ] PR review suggestions
- [ ] Changelog generation

## Testing Development Versions Locally

To test development versions of this skill without affecting your installed version:

```bash
# In the pr-creator repository root directory
bash scripts/test-skill.sh
```

This script:
1. Checks for OpenSkills installation
2. Backs up your current `~/.claude/skills/pr-creator`
3. Installs the development version from this repository
4. Shows restore instructions

**Workflow for development**:
```bash
# 1. Make changes to skills/pr-creator/scripts/create-pr.sh

# 2. Create PR description file using create_file (ONLY reliable method!)
create_file(
  filePath=".github/pr-description.tmp",
  content="Description for testing..."
)

# 3. Test with dry-run mode
DRY_RUN=true \
PR_BRANCH="test-branch" \
PR_TITLE_AI="Test title" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash skills/pr-creator/scripts/create-pr.sh

# 4. If preview looks good, run actual PR creation
DRY_RUN=false \
PR_BRANCH="test-branch" \
PR_TITLE_AI="Test title" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash skills/pr-creator/scripts/create-pr.sh

# 5. Restore original version when done
cp -r ~/.claude/skills/pr-creator.backup.YYYYMMDD_HHMMSS ~/.claude/skills/pr-creator
```

**Benefits**:
- Test changes without committing to repository
- Avoid "can't test without committing, can't commit without testing" catch-22
- Use create_file for reliable PR description creation
- Safe backup/restore workflow
