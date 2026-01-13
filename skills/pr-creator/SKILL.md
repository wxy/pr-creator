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

When the AI detects the conversation language, it will:
- Set appropriate environment variable (`PR_LANG=zh` for Chinese, etc.)
- Use matching template: Chinese → `references/pull_request_template_zh.md`, English → `references/pull_request_template.md`
- Generate all dynamic content in the conversation language

**Example**: For Chinese conversation "创建 PR", the skill will:
```bash
PR_LANG=zh bash scripts/create-pr.sh
```

This ensures the PR description language matches the user's conversation language.

## Capabilities

- Analyze commits and detect change types (BREAKING/`!`, `feat`, `fix`, `refactor`, etc.)
- Suggest a semantic version bump based on commits
- Prompt the user to accept/adjust/skip the bump
- Update `manifest.json` version (if present)
- **Detect conversation language** and use appropriate PR template
- Generate structured PR descriptions in the user's language
- **Check for existing PR** and update instead of creating duplicates
- Optionally rename branch to match PR title
- Create or update PR via `gh` CLI

## Workflow

The skill follows these steps:

1. **Check for existing PR** on current branch
   - If found → update mode (edit PR description)
   - If not found → create mode

2. **Analyze commits** since `origin/master`
   - Detect change types (BREAKING, feat, fix, etc.)
   - Count feat commits for intelligent version suggestion

3. **Suggest version bump** based on commits:
   - **Major**: BREAKING CHANGE or `!:` prefix
   - **Minor**: 2+ `feat:` commits (multiple user-facing features)
   - **Patch**: Single `feat:`, `fix`, `refactor`, `docs`, etc.

4. **Confirm with user**:
   - Accept suggestion
   - Choose alternative level (major/minor/patch)
   - Skip version update

5. **Apply bump** (if confirmed):
   - Update `manifest.json` version
   - Create commit and push

6. **Detect conversation language** and prepare PR:
   - Chinese conversation → use `references/pull_request_template_zh.md`
   - English/other → use `references/pull_request_template.md`
   - Generate all content in conversation language

7. **Generate PR description**:
   - Use language-matched template
   - Replace placeholders (version numbers, bump reason, overview)
   - Create temporary file at `.github/.pr_description_tmp.md`

8. **Optionally rename branch** to match PR title slug

9. **Create or update PR** via `gh` CLI:
   - **Create**: `gh pr create --title "..." --body-file .github/.pr_description_tmp.md --base master`
   - **Update**: `gh pr edit <number> --body-file .github/.pr_description_tmp.md`
   - Clean up temporary file

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
