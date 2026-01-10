---
name: pr-versioning
description: A universal, dependency-light skill to create PRs, suggest and apply semantic version bumps (manifest.json for now), and optionally rename the current branch to match the PR title.
---

# Universal PR + Versioning Skill

This skill automates PR creation with AI-guided semantic versioning and branch renaming.

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
