# Contributing to PR Creator

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/pr-creator.git
   cd pr-creator
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Making Changes

1. **Write your code** following the existing style and conventions
2. **Test your changes** thoroughly:
   ```bash
   bash scripts/create-pr.sh
   ```
3. **Commit with conventional messages**:
   ```bash
   git commit -m "feat: add new feature"
   git commit -m "fix: resolve issue with version detection"
   git commit -m "docs: update README"
   ```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - A new feature
- `fix:` - A bug fix
- `docs:` - Documentation only changes
- `style:` - Changes that don't affect code meaning (formatting, etc.)
- `refactor:` - Code change that neither fixes a bug nor adds a feature
- `perf:` - Code change that improves performance
- `test:` - Adding or updating tests
- `chore:` - Changes to build process, dependencies, etc.

### Code Standards

- **Bash/Shell**: Follow POSIX shell conventions
  - Use `#!/usr/bin/env bash` for shebang
  - Use `set -euo pipefail` for safety
  - Quote variables: `"$var"` instead of `$var`
  - Use `[[ ]]` for conditionals instead of `[ ]`
  - Comment complex logic

- **Documentation**: Keep README and SKILL.md updated with your changes

- **Testing**: Test your changes with different repository states:
  - With and without `manifest.json`
  - With different commit history patterns
  - On both macOS and Linux

## Submitting Changes

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub:
   - Use a clear, descriptive title
   - Reference any related issues
   - Provide context about your changes

3. **Review Process**:
   - Address feedback from maintainers
   - Keep commits atomic and meaningful
   - Ensure CI checks pass

## Reporting Issues

When reporting bugs, please include:
- Your OS and version
- Version of `git` and `gh` CLI
- Steps to reproduce
- Expected behavior vs actual behavior
- Any error messages or logs

## Feature Requests

Feature requests are welcome! Please:
- Check if the feature already exists
- Describe the use case and benefits
- Provide examples if possible

## Questions?

Open an issue or discussion thread - we're happy to help!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
