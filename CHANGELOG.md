# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-11

### Added
- Initial release of PR Creator skill
- Semantic version bump detection and suggestion
- Interactive version confirmation (accept/adjust/skip)
- Automatic branch renaming to match PR title
- `manifest.json` version update support
- Structured PR descriptions with templates
- Zero external dependencies (POSIX shell + sed)
- Cross-platform support (macOS and Linux)
- Comprehensive documentation and contribution guidelines

### Notes
- Version bump logic prioritizes: BREAKING/`!` > `feat` > others
- Requires `git` and `gh` (GitHub CLI) to be installed and authenticated
- Future versions will add support for `package.json`, `pyproject.toml`, etc.
