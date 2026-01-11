# PR Creator

A minimal, dependency-light skill to automate Pull Request creation with semantic versioning, structured descriptions, and automatic branch management.

## Features

- ✅ Analyze commits and suggest semantic version bumps
- ✅ Support for `manifest.json` version updates
- ✅ Interactive version confirmation (accept/adjust/skip)
- ✅ **Multi-language PR templates** (English/中文)
- ✅ **Automatic language detection** from conversation context
- ✅ **Smart PR update**: Updates existing PR instead of creating duplicates
- ✅ Structured PR descriptions from templates in `.github/`
- ✅ Automatic branch renaming to match PR title
- ✅ Zero external dependencies (POSIX shell + `sed`)
- ✅ Works on macOS and Linux

## Requirements

- macOS or Linux
- `git` and `gh` (GitHub CLI) installed and authenticated
- No additional dependencies (uses only shell + `sed`)
 - Recommended to install and update via OpenSkills from remote repo (wxy/pr-creator)

## Quick Start

### Option 1: Using OpenSkills (Recommended)

If you have [OpenSkills](https://github.com/openskills/openskills) installed:

```bash
# Add this skill to your project
openskills add pr-creator

# Use it to create PRs
openskills use pr-creator "Create a PR"
```

The skill will automatically:
1. Analyze your commits and suggest a semantic version bump
2. Update version in `manifest.json` (if present)
3. Generate a structured PR description
4. Optionally rename your branch to match the PR title
5. Create the PR using GitHub CLI

### Option 2: Direct Script Execution

```bash
# In your project repository
bash path/to/pr-creator/scripts/create-pr.sh
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

## Configuration

### PR Templates

The tool uses PR templates from the `references/` directory (following skill convention):
- `references/pull_request_template.md` - English template (default)
- `references/pull_request_template_zh.md` - Chinese template

When using via OpenSkills with AI conversation, the appropriate template is automatically selected based on your conversation language.

You can also force the template selection via environment variables:

- Set `PR_LANG=zh` to use the Chinese template explicitly.
- Otherwise, the script falls back to the system locale `LANG` (e.g., `zh_CN`, `zh-CN`) to auto-detect Chinese; default is English.
- **Fallback**: If the language-specific template doesn't exist, the English template is used as default.
- Placeholders (`X.Y.Z`, `A.B.C`, `major/minor/patch`) are replaced in both templates; the overview line is replaced for English and Chinese.
- **AI Integration**: When used with AI (via OpenSkills), the AI should generate all dynamic content (Overview, Changes, Notes) in the same language as the conversation.

Example:

```bash
PR_LANG=zh bash scripts/create-pr.sh
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
├── references/
│   ├── pull_request_template.md     # English PR template
│   └── pull_request_template_zh.md  # Chinese PR template
├── scripts/
│   └── create-pr.sh                 # Main script
├── skills/
│   └── pr-creator/
│       └── SKILL.md                 # Skill documentation
├── references/                      # Additional reference files
├── README.md                        # This file
├── AGENTS.md                        # OpenSkills integration
├── LICENSE                          # MIT license
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
