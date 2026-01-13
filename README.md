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

The script supports **3 reliable methods** for providing PR descriptions (choose based on your use case):

#### Method 1: Temporary File (RECOMMENDED for complex content)
Most reliable for long, complex descriptions with special characters:

```bash
mkdir -p .github
# Use printf to safely write file (more reliable than cat + heredoc)
printf '%s\n' \
  "## Overview" \
  "Detailed description here..." \
  "" \
  "## Changes" \
  "- Feature 1" \
  "- Feature 2" > .github/pr-description.tmp

PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: my feature" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash create-pr.sh
```

**Advantages**: 
- No shell escaping issues
- Handles multi-line content reliably
- Works with special characters
- Auto-cleaned after PR creation

#### Method 2: Environment Variable (for short descriptions)
Simple approach for brief PR descriptions:

```bash
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: my feature" \
PR_BODY_AI="Brief one-line description" \
VERSION_BUMP_AI="minor" \
... bash create-pr.sh
```

#### Method 3: Stdin (flexible, avoids escaping)
Pipe description from another command or script:

```bash
echo "PR description from pipeline" | \
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: my feature" \
VERSION_BUMP_AI="minor" \
... bash create-pr.sh
```

### Why These Methods are Reliable

| Method | Best For | Reliability | Escaping |
|--------|----------|-------------|----------|
| **File** | Complex, multi-line | ⭐⭐⭐⭐⭐ | None needed |
| **Env Var** | Short content | ⭐⭐⭐⭐ | Some care needed |
| **Stdin** | Dynamic content | ⭐⭐⭐⭐⭐ | None needed |
| heredoc (cat) | Legacy | ⭐⭐⭐ | Issues with quotes, variables |

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
