---
name: pr-creator
description: 智能 PR 创建工具，基于用户感知的变更影响进行语义化版本控制，支持分支重命名和双语 PR 模板。
version: 2.0.0
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
- **智能分析提交类型**：识别 BREAKING/`!`, `feat`, `fix`, `refactor`, `docs`, `style`, `perf` 等
- **用户感知优先的版本建议**：
  - 考虑变更的用户影响范围
  - 区分内部优化与面向用户的新功能
  - 提供上下文建议，让用户最终决策
- **灵活的版本控制**：用户可接受/调整/跳过版本提升
- **自动更新版本文件**：支持 `manifest.json`、`package.json` 等
- **Detect user's conversation language** and use appropriate PR template
- Generate a structured PR description (see `.github/pull_request_template.md` or `pull_request_template_zh.md`)
- **Check for existing PR** on current branch and update instead of creating new one
- Rename current branch to match the PR title (optional)
- Create or update PR via `gh`

## Workflow
1. **Check for existing PR**:
```bash
gh pr list --head $(git branch --show-current)
```
   - If PR exists → update mode (edit PR description)
   - If no PR exists → create mode

2. **Detect user's language**:
   - Analyze recent conversation messages
   - Chinese/中文 → use `references/pull_request_template_zh.md`
   - English/default → use `references/pull_request_template.md`

3. Gather changes:
```bash
git log origin/master..HEAD --format="%h %s"
git diff --stat origin/master..HEAD
```

4. Decide bump (智能分析版本变更等级):
- **Major (破坏性更新)**:
  - 有 BREAKING 标记或 `!` 的提交
  - API 不兼容变更
  
- **Minor (新功能)**:
  - 至少 2 个 `feat:` 提交且面向用户
  - 新增用户可见功能模块
  - 重要的体验改进
  
- **Patch (修复/优化)**:
  - 单一 `feat:` 且为内部优化/UI 调整
  - `fix:` Bug 修复
  - `refactor:` 内部重构
  - `docs:` 文档更新
  - `style:` 样式调整
  - `perf:` 性能优化

**判断原则**:
- 关注**用户感知的变化**，而非开发者的提交类型
- UI 优化、内部重构通常是 patch，除非是全新模块
- 询问用户确认变更等级，提供上下文建议

**示例场景**:
```
场景 1: UI 优化 + Bug 修复
提交: feat(ui): 优化推荐设置布局, fix: 修复存储键未定义错误
建议: PATCH (0.5.0 → 0.5.1)
理由: UI 调整对用户是改进而非新功能

场景 2: 新增完整功能模块
提交: feat: 添加 RSS 订阅管理, feat: 实现文章自动翻译
建议: MINOR (0.5.0 → 0.6.0)
理由: 两个独立的用户可见新功能

场景 3: API 破坏性变更
提交: feat!: 重构存储 API，不兼容旧版本
建议: MAJOR (0.5.0 → 1.0.0)
理由: 破坏性变更影响扩展升级
```

5. Confirm with user:
- Accept suggestion
- Try alternative level
- Skip bump

6. Apply bump (if confirmed):
- Update `manifest.json` version via sed
- Create commit and push

7. Generate PR description:
 - Use language-appropriate template from `references/pull_request_template.md` or `references/pull_request_template_zh.md`
 - Generate temporary file at `.github/.pr_description_tmp.md` (not committed to git)
 - Include version bump details and key changes

## Installation & Version Control Notes

- Installed skills are placed under `.claude/skills/` and are installation artifacts; do not commit them to git. The repository includes `.gitignore` rules to exclude `.claude/`.
- Universal installs (shared across projects) use `.agent/skills/`. These are also installation artifacts and excluded from version control.
- The source of truth is the remote repository `wxy/pr-creator`. Re-run `openskills install wxy/pr-creator -y` and `openskills sync -y` after updates to stay current.

8. Rename branch (optional):
- Derive slug from PR title
- `git branch -m <new>` and `git push --set-upstream origin <new>`

9. Create or update PR via `gh`:
   - **Create**: `gh pr create --title "..." --body-file .github/.pr_description_tmp.md`
   - **Update**: `gh pr edit <number> --body-file .github/.pr_description_tmp.md`
   - Temporary file is cleaned up after PR creation/update

## Minimal Script
See `scripts/create-pr.sh` for an implementation using POSIX shell and `gh`.

## Future Enhancements
- ~~更智能的版本判断逻辑（已实现：v2.0）~~
- Add support for more project files (pyproject.toml, Cargo.toml)
- CI hooks to validate version bump after PR creation
- 自动生成 CHANGELOG.md 条目

## License
MIT
