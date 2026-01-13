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

### 方法 1：使用临时文件（长描述）- RECOMMENDED

```bash
# AI 生成描述后
mkdir -p .github
printf '%s\n' \
  "## 功能说明" \
  "这个 PR 实现了..." \
  "" \
  "## 改动列表" \
  "- Feature 1" > .github/pr-description.tmp

# 然后调用脚本
PR_BRANCH="$(git rev-parse --abbrev-ref HEAD)" \
PR_TITLE_AI="feat: 功能名称" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash create-pr.sh
```

**何时使用**：描述复杂、有多行、有特殊字符

### 方法 2：环境变量（短描述）

```bash
PR_BRANCH="$(git rev-parse --abbrev-ref HEAD)" \
PR_TITLE_AI="feat: 简单功能" \
PR_BODY_AI="这是一行描述" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="minor" \
CURRENT_VERSION="1.0.0" \
NEW_VERSION="1.1.0" \
VERSION_FILE="manifest.json" \
bash create-pr.sh
```

**何时使用**：描述简短，无特殊格式

### 方法 3：stdin 管道（动态内容）

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

## 完整工作流示例（中文场景）

```bash
#!/bin/bash

# 1. 当前分支和提交分析
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
CURRENT_VERSION="$(grep '"version"' manifest.json | head -1 | sed 's/.*"\([^"]*\)".*/\1/')"

# 2. 分析提交，判断版本
COMMIT_COUNT="$(git log origin/master..HEAD | grep -c '^commit')"
HAS_BREAKING="$(git log origin/master..HEAD --format=%B | grep -c 'BREAKING CHANGE' || echo 0)"
HAS_FEAT="$(git log origin/master..HEAD --format=%b | grep -c 'feat:' || echo 0)"

if [[ $HAS_BREAKING -gt 0 ]]; then
  BUMP="major"
  NEW_VERSION="2.0.0"  # 示例
elif [[ $HAS_FEAT -ge 2 ]]; then
  BUMP="minor"
  NEW_VERSION="1.1.0"  # 示例
else
  BUMP="patch"
  NEW_VERSION="1.0.1"  # 示例
fi

# 3. 生成 PR 描述（中文）
mkdir -p .github
printf '%s\n' \
  "## 功能概览" \
  "" \
  "本 PR 实现了新的用户认证系统。" \
  "" \
  "## 主要改动" \
  "- 添加了 OAuth 2.0 支持" \
  "- 实现了 JWT token 管理" \
  "- 添加了用户会话管理" \
  "" \
  "## 测试" \
  "- 单元测试覆盖率 95%" \
  "- 集成测试通过" \
  > .github/pr-description.tmp

# 4. 调用技能脚本
PR_BRANCH="$BRANCH" \
PR_TITLE_AI="feat: 新增用户认证系统" \
PR_LANG="zh-CN" \
VERSION_BUMP_AI="$BUMP" \
CURRENT_VERSION="$CURRENT_VERSION" \
NEW_VERSION="$NEW_VERSION" \
VERSION_FILE="manifest.json" \
bash skills/pr-creator/scripts/create-pr.sh
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
