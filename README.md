# PR Creator

A minimal, dependency-light skill to automate Pull Request creation with semantic versioning, structured descriptions, and automatic branch management.

## Features

- ✅ Analyze commits and suggest semantic version bumps
- ✅ Support for `manifest.json` version updates
- ✅ Interactive version confirmation (accept/adjust/skip)
- ✅ Structured PR descriptions from templates
- ✅ Automatic branch renaming to match PR title
- ✅ Zero external dependencies (POSIX shell + `sed`)
- ✅ Works on macOS and Linux

## Requirements

- macOS or Linux
- `git` and `gh` (GitHub CLI) installed and authenticated
- No additional dependencies (uses only shell + `sed`)

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
1. Analyze commits since `origin/master`
2. Suggest a semantic version bump (major/minor/patch)
3. Prompt you to confirm or adjust the version
4. Update `manifest.json` version (if present)
5. Prompt for a PR title and generate a description
6. Optionally rename the current branch to match the PR title
7. Create a PR via `gh` CLI

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

The script looks for version information in `manifest.json`:

```json
{
  "name": "my-project",
  "version": "1.0.0"
}
```

If no version is found, it defaults to `0.1.0`.

## File Structure

```
pr-creator/
├── scripts/
│   └── create-pr.sh          # Main script
├── skills/
│   └── pr-creator/
│       └── SKILL.md          # Skill documentation
├── references/
│   └── pr-template.md        # PR description template
├── README.md                 # This file
├── LICENSE                   # MIT license
└── CONTRIBUTING.md           # Contribution guidelines
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
