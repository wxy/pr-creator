# SKILL.md 精简方案

## 对比

| 指标 | 原始版本 | 优化版本 | 改进 |
|------|---------|---------|------|
| **行数** | 347 | 115 | **↓ 67%** |
| **章节** | 14 | 9 | **↓ 36%** |
| **代码示例** | 13+ | 3 | **↓ 77%** |
| **强调词** | 多处 CRITICAL/⭐ | 1 处 CRITICAL | **↓ 87%** |

## 删除的内容

### 🗑️ 完全删除（不必要）
1. **Manual Installation** (6行)
   - 对 OpenSkills 安装用户无关
   - README 已有详细安装说明

2. **"For Development" vs "After Installation"** (20行)
   - 重复描述不同路径
   - 优化版用简单说明代替

3. **"Why This Design?"** (18行)
   - 历史背景，不影响使用
   - 不是 AI 助手需要知道的

4. **"Design Principles"** (10行)
   - 高层哲学，不需要在 SKILL 中
   - 可放在 README 或贡献指南

5. **"Future Enhancements"** (7行)
   - 与当前使用无关
   - 应在项目问题跟踪中

6. **"Testing Development Versions Locally"** (42行)
   - 这是开发任务，不是 SKILL 文档
   - 应该放在 README 的"开发者指南"部分

### 📉 大幅简化

1. **"How It Works"** (58行 → 20行)
   - 删除重复的详细解释
   - 保留核心步骤

2. **"Capabilities"** (23行 → 7行)
   - 从详细描述改为简洁列表
   - 关键功能一目了然

3. **"Workflow (AI Perspective)"** (22行 → 移除)
   - 内容与"How It Works"重复
   - 通过"How AI Should Use This Skill"代替

4. **"Dry-Run Mode"** (20行 → 8行)
   - 删除过度解释
   - 保留核心用法

5. **环境变量说明**
   - 删除"CRITICAL NOTES"中的重复强调
   - 简化表格，去掉"Required"列（所有的都是必要的）
   - 删除"PR_BODY_AI"（仅用于手动，AI 不需要知道）

## 保留的精要

✅ **Quick Start** - 用户如何触发技能
✅ **How AI Should Use** - AI 的标准工作流
✅ **Environment Variables** - 必要的参数表
✅ **Capabilities** - 功能速览
✅ **Testing & Preview** - 如何验证
✅ **Version Detection** - 版本规则
✅ **Key Points** - 技能特点总结
✅ **Dependencies** - 运行要求

## 为什么这样做更好

1. **减少认知负荷**：从 14 个章节降到 9 个
2. **避免矛盾**：不同版本的说明可能导致混淆
3. **聚焦核心**：突出 AI 助手真正需要知道的
4. **防止歧义**：例如多个路径说明可能导致错误选择
5. **易于维护**：更新代码时，需要修改的文档更少

## 实施建议

1. 用 SKILL_OPTIMIZED.md 替换 SKILL.md
2. 将"Testing Development Versions Locally"移到 README
3. 将"Why This Design?"和"Design Principles"移到 CONTRIBUTING.md
4. 在 AI_USAGE.md 中补充高级话题
