# PR Creator

A minimal, dependency-light skill to automate Pull Request creation with semantic versioning, structured descriptions, and automatic branch management.

## Features

- ✅ **AI-Driven Automation**: Full autonomous PR creation with AI-generated titles and version decisions
- ✅ **Multi-Language Support**: PR titles and descriptions follow your conversation language (中文, English, etc.)
- ✅ Analyze commits and suggest semantic version bumps
- ✅ Support for multiple version file formats (manifest.json, package.json, pyproject.toml, setup.py)
- ✅ **Smart PR update**: Updates existing PR instead of creating duplicates
- ✅ **Long Description Support**: PR descriptions can be written to `.github/pr-description.tmp` for complex content
- ✅ Pure AI-generated descriptions (no templates)
- ✅ Zero external dependencies (POSIX shell + `sed` + `git` + `gh`)

## Requirements

- macOS or Linux
- `git` and `gh` (GitHub CLI) installed and authenticated
- No additional dependencies (uses only shell + `sed`)
 - Recommended to install and update via OpenSkills from remote repo (wxy/pr-creator)

## Quick Start

### Option 1: Using OpenSkills (Recommended)

If you have [OpenSkills](https://github.com/openskills/openskills) installed:

```bash
# Install the skill
openskills install wxy/pr-creator -y
openskills sync -y
```

Then in your AI conversation, simply say:
- "创建 PR" (Chinese)
- "Create a PR" (English)

The AI will automatically:
1. Analyze your commits and determine optimal PR title and version bump
2. Generate PR title and description in your conversation language
3. Update version in detected file (manifest.json, package.json, pyproject.toml, or setup.py)
4. Create or update the PR using GitHub CLI - **zero interaction required**

**Language Note**: PR titles and descriptions will follow your conversation language automatically via the `PR_LANG` environment variable.

### Option 2: Direct Script Execution

```bash
# After installing via OpenSkills
bash .claude/skills/pr-creator/scripts/create-pr.sh

# Or run from this repository
bash skills/pr-creator/scripts/create-pr.sh
```

The script will:
1. **Check for existing PR** on the current branch
2. Analyze commits since `origin/master`
3. Suggest a semantic version bump (major/minor/patch)
4. Prompt you to confirm or adjust the version
5. Update `manifest.json` version (if present)
6. Prompt for a PR title and select appropriate language template
7. Optionally rename the current branch to match the PR title
8. **Create a new PR or update existing PR** via `gh` CLI

## Workflow Example

```
$ bash scripts/create-pr.sh
Analyzing commits and current version...
[INFO] Current branch: feature/my-feature
[INFO] Current version: 1.2.3
[INFO] Suggested bump: minor
[INFO] Proposed version: 1.3.0

Confirm version bump
A) Accept suggestion (1.2.3 → 1.3.0, minor)
B) Choose another level
C) Skip version update
Select [A/B/C]: A

Updating manifest.json version (1.2.3 → 1.3.0)
Prepare PR information
PR Title: Add new dashboard feature
Rename branch to 'pr/add-new-dashboard-feature'? [y/N]: y

Creating PR via gh...
[INFO] PR created successfully
```

## Versioning Rules

The script automatically detects the appropriate version bump based on commit messages:

- **MAJOR**: Commits with `BREAKING CHANGE` or `!:` prefix
- **MINOR**: Commits with `feat:` prefix (no breaking changes)
- **PATCH**: All other commits (fixes, refactors, etc.)

Follows [Semantic Versioning](https://semver.org/) and [Conventional Commits](https://www.conventionalcommits.org/).

## Advanced Usage

### PR Description Methods

The script supports **multiple methods** for providing PR descriptions:

#### Method 1: create_file Tool (ONLY OPTION for AI Assistants)
AI assistants MUST use the `create_file` tool to create description files:

```python
# ONLY reliable method for AI
create_file(
  filePath=".github/pr-description.tmp",
  content="""## Overview
Detailed description...

## Changes
- Feature 1
- Feature 2
"""
)

# Then call the script with correct path
run_in_terminal(
  command="bash skills/pr-creator/scripts/create-pr.sh",
  env={
    "PR_BRANCH": "feat/my-feature",
    "PR_TITLE_AI": "feat: new feature",
    "PR_LANG": "en",
    "VERSION_BUMP_AI": "minor",
    "CURRENT_VERSION": "1.0.0",
    "NEW_VERSION": "1.1.0",
    "VERSION_FILE": "manifest.json"
  }
)
```

**Why create_file is REQUIRED for AI**: 
- No shell escaping issues
- No heredoc conflicts
- Completely reliable in AI environments
- **Other methods are NOT suitable for AI**

#### Method 2: printf (for Human Terminal Use - NOT for AI)
When executing manually in terminal, use printf for reliable file creation:

```bash
mkdir -p .github
# Use printf to safely write file (better than cat + heredoc)
printf '%s\n' \
  "## 功能概览" \
  "本 PR 添加了新的功能..." \
  "" \
  "## 主要改动" \
  "- 功能 1" \
  "- 功能 2" > .github/pr-description.tmp

PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: 新增功能说明" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash skills/pr-creator/scripts/create-pr.sh
```

**When to use printf**: Only for manual terminal use. AI assistants should ALWAYS use create_file.
- No variable expansion issues: `$var` is treated as literal text
- No quote escaping needed: Single or double quotes work fine
- No heredoc delimiter conflicts: No need to worry about `EOF` appearing in content
- Better error handling: Each line is a separate argument

#### Method 3: Environment Variable (for short descriptions - NOT for AI)
Simple approach for brief PR descriptions (manual use only):

```bash
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: 新增功能说明" \
PR_BODY_AI="这是一个简短的 PR 描述，只适合手动执行" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash skills/pr-creator/scripts/create-pr.sh
```

**Note**: Not recommended for AI. Use create_file instead.

#### Method 4: Stdin (NOT for AI - use create_file instead)
Pipe description from another command or script:

```bash
# Example: For manual terminal use only
generate_description() {
  printf '%s\n' \
    "## Feature Description" \
    "This PR implements..." \
    "" \
    "## Testing" \
    "1. Step 1" \
    "2. Step 2"
}

generate_description | \
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: new feature" \
PR_LANG="en" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="package.json" \
bash skills/pr-creator/scripts/create-pr.sh
```

**Note**: This is for manual terminal use. AI assistants should ONLY use create_file method.

**Best for**: Dynamic content, avoiding escaping issues

### PR Description Methods - Summary

| Method | Best For | Reliability | Recommended for AI |
|--------|----------|-------------|-------------------|
| **create_file** | All content sizes | ⭐⭐⭐⭐⭐ | ✅ **ONLY for AI** |
| **printf** | Manual terminal use | ⭐⭐⭐⭐ | ❌ No |
| **Env Var** | Short manual content | ⭐⭐⭐ | ❌ No |
| **Stdin** | Manual dynamic content | ⭐⭐⭐⭐ | ❌ No |

**KEY RULE**: AI assistants MUST use `create_file()` method. Other methods are for manual terminal use only.

### Language Control

Use the `PR_LANG` environment variable to control the language of PR content:

```bash
PR_LANG="zh-CN" \  # Chinese
PR_BRANCH="..." \
PR_TITLE_AI="feat: 我的功能" \
... bash create-pr.sh
```

Supported values: `zh-CN`, `en`, or any ISO language code.

```bash
PR_LANG=zh bash skills/pr-creator/scripts/create-pr.sh
```

### Dry-Run Mode (Testing)

Test the script without making any modifications to your repository:

```bash
DRY_RUN=true \
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: My feature" \
PR_LANG="en" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
bash create-pr.sh
```

The script will display a preview of what would happen:
- Version bump details
- Git commits that would be made
- PR that would be created

**No files are modified** when `DRY_RUN=true`. This is useful for:
- Testing PR descriptions before creating them
- Verifying version updates
- Validating branch names
- Checking commit messages

### Testing Development Versions Locally

To test development versions of this skill without affecting the installed version:

```bash
# Backup your current installation and install development version
bash scripts/test-skill.sh

# Now test the skill with DRY_RUN or manual testing
DRY_RUN=true bash ~/.claude/skills/pr-creator/scripts/create-pr.sh

# To restore the original version, run the command shown by test-skill.sh
# Example: cp -r ~/.claude/skills/pr-creator.backup.YYYYMMDD_HHMMSS ~/.claude/skills/pr-creator
```

This script:
- Checks for OpenSkills installation
- Backs up your current `~/.claude/skills/pr-creator` with a timestamp
- Copies the development version from this repository
- Shows you how to restore the original version if needed

**Perfect for**: Developing and testing new features before committing

### Version Configuration

The script looks for version information in `manifest.json`:

```json
{
  "name": "my-project",
  "version": "1.0.0"
}
```

If no version is found, it defaults to `0.1.0`.

### OpenSkills Installation & Version Control

- Install from remote to stay up-to-date:

  ```bash
  openskills install wxy/pr-creator -y
  openskills sync -y
  ```

- Universal install (shared across projects) writes to `.agent/skills/`:

  ```bash
  openskills install wxy/pr-creator -u -y
  openskills sync -y
  ```

- Installed skills are placed under `.claude/skills/` and are considered build/install artifacts. They should not be committed to git. The repository includes `.gitignore` rules to exclude `.claude/`.

- If using `--universal`, installed skills reside under `.agent/skills/` and are also excluded from version control.

- The source of truth is the remote repository (wxy/pr-creator). Re-run installation after pulling changes to update local skills.

## File Structure

```
pr-creator/
├── .github/
│   └── .pr_description_tmp.md       # Temporary PR description (not committed)
├── skills/
│   └── pr-creator/                  # Complete skill package
│       ├── SKILL.md                 # Skill documentation
│       ├── scripts/
│       │   └── create-pr.sh         # Main script
│       └── references/
│           ├── pull_request_template.md     # English PR template
│           └── pull_request_template_zh.md  # Chinese PR template
├── README.md                        # This file
├── AGENTS.md                        # OpenSkills integration
├── LICENSE                          # MIT license
├── CHANGELOG.md                     # Version history
└── CONTRIBUTING.md                  # Contribution guidelines
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute improvements and bug fixes.

## Future Enhancements

- Support for `package.json` and `pyproject.toml`
- Customizable version bump strategies
- CI/CD hooks for validation
- Support for Squash commits
- Git tag creation with version bumps

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please open an issue on the repository.
