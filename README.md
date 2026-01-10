# Universal PR Skill

A minimal, dependency-light skill to:
- Create PRs with structured descriptions
- Auto-suggest and update version numbers (currently supports `manifest.json`)
- Confirm version changes with the user
- Rename the current branch to match the PR title

## Requirements
- macOS/Linux
- `git` and `gh` (GitHub CLI) installed and authenticated
- No external dependencies (uses POSIX shell + `sed`)

## Quick Start

```bash
# In your project repository
bash path/to/universal-pr-skill/scripts/create-pr.sh
```

The script will:
1. Analyze commits since `origin/master`
2. Suggest a semantic version bump (major/minor/patch)
3. Prompt you to confirm or adjust the version
4. Update `manifest.json` version (if present)
5. Prompt a PR title and generate a description
6. Optionally rename the current branch to match the title
7. Create a PR via `gh` CLI

## Notes
- Version bump logic prioritizes: BREAKING/`!` > `feat` > others
- Manifest path searched at repo root as `manifest.json`
- Future: add support for `package.json`, `pyproject.toml`, etc.

## License
MIT
