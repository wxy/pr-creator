---
name: pr-creator
description: A minimal, dependency-light skill to create PRs with semantic versioning support, structured descriptions, and automatic branch renaming.
---

# PR Creator Skill

This skill automates PR creation with AI-guided semantic versioning and branch renaming.

## Installation

### Using OpenSkills

```bash
# Add this skill to your project
openskills add pr-creator

# Or install from a specific source
openskills add github:your-org/pr-creator
```

### Manual Installation

Clone this repository to your local skills directory or use the script directly.

## Usage

### With OpenSkills (Recommended)

```bash
# Use the skill in your project
openskills use pr-creator "Create a PR"

# Or trigger with specific commands
openskills use pr-creator "Suggest version bump"
openskills use pr-creator "Update version and open PR"
```

### Direct Script Execution

```bash
bash path/to/scripts/create-pr.sh
```

## Triggers
- "Create a PR"
- "Suggest version bump"
- "Update version and open PR"

## Capabilities
- Analyze commits and detect change types (BREAKING/`!`, `feat`, `fix`, `refactor`, etc.)
- Suggest a semantic version bump: major > minor > patch
- Prompt the user to accept/adjust/skip the bump
- Update `manifest.json` version (if present)
- Generate a structured PR description (see references/pr-template.md)
- Rename current branch to match the PR title (optional)
- Create PR via `gh`

## Workflow
1. Gather changes:
```bash
git log origin/master..HEAD --format="%h %s"
git diff --stat origin/master..HEAD
```
2. Decide bump:
- BREAKING or `!` in commits → major
- Any `feat:` → minor
- Otherwise → patch
3. Confirm with user:
- Accept suggestion
- Try alternative level
- Skip bump
4. Apply bump (if confirmed):
- Update `manifest.json` version via sed
- Create commit and push
5. Generate PR description:
- Use `references/pr-template.md`
- Include version bump details and key changes
6. Rename branch (optional):
- Derive slug from PR title
- `git branch -m <new>` and `git push --set-upstream origin <new>`
7. Create PR via `gh`.

## Minimal Script
See `scripts/create-pr.sh` for an implementation using POSIX shell and `gh`.

## Future Enhancements
- Add support for more project files (package.json, pyproject.toml)
- CI hooks to validate version bump after PR creation

## License
MIT
