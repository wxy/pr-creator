---
name: pr-creator
description: AI-native skill to automate PR creation with semantic versioning and intelligent descriptions.
---

# PR Creator Skill

Automates PR creation with AI-generated titles, descriptions, and semantic versioning.

## Quick Start

Tell the AI in conversation:
- "创建 PR" (Chinese)
- "Create a PR" (English)

The AI will analyze commits, generate PR details, and create/update the PR automatically.

## How AI Should Use This Skill

1. **Analyze** your branch and commits
   - Detect commit types (feat, fix, BREAKING, etc.)
   - Identify version file and current version
   - Suggest semantic version bump

2. **Generate** PR decisions
   - PR title and description
   - New version number and bump level (major/minor/patch/skip)

3. **Execute** using this exact workflow:
   ```python
   # Step 1: Create description file (REQUIRED for AI)
   create_file(
     filePath=".github/pr-description.tmp",
     content="<AI-generated PR description>"
   )
   
   # Step 2: Run the script
   run_in_terminal(
     command="bash skills/pr-creator/scripts/create-pr.sh",
     env={
       "PR_BRANCH": "<current branch>",
       "PR_TITLE_AI": "<AI-generated title>",
       "PR_LANG": "zh-CN",  # or "en", etc.
       "VERSION_BUMP_AI": "minor",  # major/minor/patch/skip
       "CURRENT_VERSION": "1.0.0",
       "NEW_VERSION": "1.1.0",
       "VERSION_FILE": "manifest.json"  # or package.json, pyproject.toml, setup.py
     }
   )
   ```

**CRITICAL**: Always use `create_file()` to create the description file. No other method is reliable for AI.

## Required Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `PR_BRANCH` | Current branch | `feat/my-feature` |
| `PR_TITLE_AI` | PR title | `feat: add authentication` |
| `PR_LANG` | Language | `zh-CN` or `en` |
| `VERSION_BUMP_AI` | Version bump | `major`, `minor`, `patch`, or `skip` |
| `CURRENT_VERSION` | Current version | `1.0.0` |
| `NEW_VERSION` | New version | `1.1.0` |
| `VERSION_FILE` | Version file | `manifest.json`, `package.json`, `pyproject.toml`, or `setup.py` |

The script automatically reads PR description from `.github/pr-description.tmp` created via `create_file()`.

## Capabilities

✅ Semantic versioning (major/minor/patch)
✅ Multi-format version file support (manifest.json, package.json, pyproject.toml, setup.py)
✅ Smart PR detection (updates existing PRs instead of creating duplicates)
✅ Language awareness (PR content follows your conversation language)
✅ Dry-run mode (`DRY_RUN=true` to preview without creating PR)
✅ Automatic PR attribution footer

## Testing & Preview

Use dry-run mode to preview changes before creating the PR:

```bash
DRY_RUN=true \
PR_BRANCH="feat/test" \
PR_TITLE_AI="feat: test" \
PR_LANG="en" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash skills/pr-creator/scripts/create-pr.sh
```

Shows what would be created without modifying anything.

## Version Detection

The script detects version bumps based on commit messages:
- **BREAKING CHANGE** or commits with `!:` prefix → major version
- **feat:** prefix → minor version
- All other commits (fixes, refactors, etc.) → patch version

See [Conventional Commits](https://www.conventionalcommits.org/) for details.

## Key Points

- **Minimal**: Single script, ~150 lines, no templates
- **Focused**: AI generates all content, script just executes decisions
- **Reliable**: No shell escaping issues, pure AI-native design
- **Transparent**: All decisions visible in environment variables

## Dependencies

- `git` - for version control
- `gh` - GitHub CLI for PR operations
- macOS or Linux
