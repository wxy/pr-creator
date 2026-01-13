# AI 如何使用 PR Creator 技能

当用户要求"创建 PR"时，AI 应该按照以下流程自动使用该技能。

## 流程概述

```
用户请求: "创建 PR"
    ↓
AI 分析工作区
    ↓
AI 收集所有信息
    ↓
AI 调用技能脚本
    ↓
PR 自动创建/更新
```

## AI 的决策职责

在调用脚本前，AI 需要做出以下决策：

### 1. 分析提交历史
```bash
git log origin/master..HEAD --pretty=format:"%h %s"
```

根据提交消息判断：
- BREAKING CHANGE / `!:` → **major**
- 2+ `feat:` commits → **minor**  
- 其他情况 → **patch**

### 2. 检测版本文件
```bash
# 按优先级检查
test -f manifest.json && echo "manifest.json"
test -f package.json && echo "package.json"
test -f pyproject.toml && echo "pyproject.toml"
test -f setup.py && echo "setup.py"
```

### 3. 确定版本号
从检测到的版本文件中提取当前版本，计算新版本。

### 4. 生成 PR 内容
根据用户的对话语言，生成：
- **PR_TITLE_AI**: 简洁的功能描述
- **PR_BODY_AI**: 详细的改动说明

重要：PR 的语言应该跟随对话语言！

## 调用脚本的三种方法

### 方法 1：使用 create_file 工具创建临时文件 - MOST RECOMMENDED FOR AI

**AI 助手应该使用 `create_file` 工具创建描述文件（最可靠）**：

```python
# Step 1: 使用 create_file 工具创建 PR 描述
create_file(
  filePath=".github/pr-description.tmp",
  content="""## 功能说明

这个 PR 实现了新的用户认证功能。

## 改动列表
- 添加 OAuth 2.0 支持
- 实现 JWT token 管理
- 添加用户会话功能

## 测试
- 单元测试覆盖率 95%
- 集成测试通过
"""
)

# Step 2: 然后调用脚本
run_in_terminal(
  command="bash skills/pr-creator/scripts/create-pr.sh",
  env={
    "PR_BRANCH": "feat/auth-system",
    "PR_TITLE_AI": "feat: 新增用户认证系统",
    "PR_LANG": "zh-CN",
    "VERSION_BUMP_AI": "minor",
    "CURRENT_VERSION": "1.0.0",
    "NEW_VERSION": "1.1.0",
    "VERSION_FILE": "manifest.json"
  }
)
```

**为什么 create_file 最可靠**：
- ✅ 无需担心 shell 转义
- ✅ 无需担心特殊字符
- ✅ 无 heredoc 或引号问题
- ✅ 在 AI 环境中最稳定
- ✅ 支持任意长度的内容

**何时使用**：AI 助手创建 PR 时（推荐）

### 方法 2：使用 printf 在 shell 中（人工执行时）

```bash
mkdir -p .github
printf '%s\n' \
  "## 功能说明" \
  "这个 PR 实现了..." \
  "" \
  "## 改动列表" \
  "- Feature 1" > .github/pr-description.tmp

PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: 功能名称" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash create-pr.sh
```

**何时使用**：人工在终端中执行时

### 方法 3：环境变量（短描述）

```bash
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: 简单功能" \
PR_BODY_AI="这是一行简短描述" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
bash create-pr.sh
```

**何时使用**：描述非常简短（一句话）

### 方法 4：stdin 管道（动态内容）

```bash
# 从其他脚本生成描述
generate_pr_body() {
  printf '%s\n' \
    "## 功能说明" \
    "..."
}

generate_pr_body | \
PR_BRANCH="..." \
PR_TITLE_AI="..." \
PR_LANG="zh-CN" \
bash create-pr.sh
```

**何时使用**：从其他命令/脚本动态生成内容

## 必需环境变量

| 变量 | 来源 | 示例 |
|------|------|------|
| `PR_BRANCH` | 当前分支 | `feat/my-feature` |
| `PR_TITLE_AI` | AI 生成 | `feat: 新增用户认证功能` |
| `VERSION_BUMP_AI` | AI 分析 | `minor` |
| `CURRENT_VERSION` | 文件读取 | `1.0.0` |
| `NEW_VERSION` | AI 计算 | `1.1.0` |
| `VERSION_FILE` | AI 检测 | `manifest.json` |

## 可选环境变量

| 变量 | 用途 | 默认值 |
|------|------|--------|
| `PR_LANG` | PR 语言 | `en` |
| `PR_BODY_AI` | 短描述 | （无） |
| `DRY_RUN` | 试运行模式 | `false` |

## 试运行模式（DRY_RUN）

在实际创建 PR 前，可以使用试运行模式预览所有操作：

```bash
# 预览所有操作，不做任何修改
DRY_RUN=true \
PR_BRANCH="feat/my-feature" \
PR_TITLE_AI="feat: 新增功能" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash create-pr.sh
```

**试运行模式会显示**：
- 将要检出的分支
- 将要更新的版本号
- 将要执行的 git 命令
- PR 标题和描述预览
- 不会实际修改任何文件或创建 PR

## 完整工作流示例（AI 助手使用 create_file）

```python
#!/usr/bin/env python
# AI 助手的完整工作流

# Step 1: 分析当前分支和提交
branch = run_command("git rev-parse --abbrev-ref HEAD")  # feat/auth-system
commits = run_command("git log origin/master..HEAD --pretty=format:'%s'")

# Step 2: 检测版本文件和当前版本
version_file = None
current_version = None

if file_exists("manifest.json"):
    version_file = "manifest.json"
    content = read_file("manifest.json")
    current_version = extract_version(content)  # "1.0.0"
elif file_exists("package.json"):
    version_file = "package.json"
    # ... similar logic

# Step 3: 分析提交，判断版本提升
has_breaking = "BREAKING CHANGE" in commits or "!:" in commits
feat_count = commits.count("feat:")

if has_breaking:
    bump_level = "major"
    new_version = "2.0.0"
elif feat_count >= 2:
    bump_level = "minor"
    new_version = "1.1.0"
else:
    bump_level = "patch"
    new_version = "1.0.1"

# Step 4: 生成 PR 描述（跟随对话语言）
pr_language = detect_conversation_language()  # "zh-CN"

# Step 5: 使用 create_file 工具创建描述（最可靠）
create_file(
    filePath=".github/pr-description.tmp",
    content="""## 功能概览

本 PR 实现了新的用户认证系统。

## 主要改动

### 1. OAuth 2.0 集成
- 添加 Google OAuth 支持
- 添加 GitHub OAuth 支持
- 实现 OAuth 回调处理

### 2. JWT Token 管理
- 实现 token 生成和验证
- 添加 refresh token 机制
- 实现 token 过期管理

### 3. 用户会话
- 添加会话存储
- 实现会话过期处理
- 添加多设备登录支持

## 测试

- ✅ 单元测试覆盖率: 95%
- ✅ 集成测试: 通过
- ✅ 安全审计: 通过

## 破坏性改动

无
"""
)

# Step 6: 调用技能脚本
run_in_terminal(
    command="bash skills/pr-creator/scripts/create-pr.sh",
    explanation="使用 pr-creator 技能创建 PR",
    env={
        "PR_BRANCH": branch,
        "PR_TITLE_AI": "feat: 新增用户认证系统",
        "PR_LANG": pr_language,
        "VERSION_BUMP_AI": bump_level,
        "CURRENT_VERSION": current_version,
        "NEW_VERSION": new_version,
        "VERSION_FILE": version_file
    }
)

# 脚本会自动：
# - 更新版本文件
# - 提交版本更改
# - 创建或更新 PR
# - 清理临时文件
```

## 错误处理

如果脚本返回错误：

```bash
if ! bash create-pr.sh; then
  echo "PR 创建失败，请检查："
  echo "1. 所有必需环境变量是否设置"
  echo "2. 分支是否存在"
  echo "3. GitHub 认证是否有效"
fi
```

## 重要提示

1. **语言一致性**：`PR_LANG` 必须与对话语言一致
2. **printf 优于 heredoc**：使用 printf 而不是 cat + heredoc
3. **版本计算**：AI 需要准确判断版本提升级别
4. **分支管理**：确保在正确的分支上执行脚本
5. **自动 PR 更新**：如果 PR 已存在，脚本会自动更新而不是创建重复

## 调试技巧

查看脚本执行过程：
```bash
PR_BRANCH="..." PR_TITLE_AI="..." bash -x create-pr.sh
```

查看版本文件内容：
```bash
cat manifest.json | grep version
```

查看现有 PR：
```bash
gh pr list --head "$BRANCH"
```
