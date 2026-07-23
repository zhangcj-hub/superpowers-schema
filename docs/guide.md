# superpowers-schema 使用说明

> v1.2.0 | OpenCode 平台 | 简体中文
>
> 本文件是 superpowers-schema 在 **OpenCode** 环境下的使用手册。英文 canonical 文档见 [`superpowers-schema/README.md`](./superpowers-schema/README.md),简中版见 [`superpowers-schema/README.zh-CN.md`](./superpowers-schema/README.zh-CN.md)。

---

## 术语表

| 术语 | 含义 |
|---|---|
| **change** | 一次变更的完整生命周期：从规划到实现到归档 |
| **artifact** | change 目录下产出的文件（brainstorm.md、proposal.md、verify.md 等） |
| **schema** | OpenSpec 的项目级配置，定义 change 走什么流程（本 schema 是 superpowers-schema） |
| **PR** | Pull Request，把分支改动合并回主干的提议 |
| **worktree** | git 隔离工作树，apply 阶段用它做实现，不污染主分支 |
| **delta spec** | change 里对 spec 的改动（新增/修改/删除），archive 时同步到主 specs |
| **TDD** | 测试驱动开发：先写失败测试 → 写最小代码通过 → 重构 |
| **contract** | execution-contract.md 的简称，规划阶段的最终产出，需用户批准后才能 apply |
| **Full / Hotfix / Tweak** | 三种模式：Full 走完整流程，Hotfix 跳过规划，Tweak 直接编辑 |

---

## 目录

- [一、安装与前置条件](#一安装与前置条件)
- [二、工作流总览](#二工作流总览)
- [三、命令清单](#三命令清单)
- [四、Full 模式完整流程](#四full-模式完整流程)
- [五、快速模式（Hotfix / Tweak）](#五快速模式hotfix--tweak)
- [六、bug 调查与会话恢复](#六bug-调查与会话恢复)
- [七、实用场景](#七实用场景)
- [八、运维](#八运维)
- [相关链接](#相关链接)

---

## 一、安装与前置条件

### 安装

```bash
# 1. 在项目中初始化 OpenSpec（OpenCode 模式）
cd ~/your-project
openspec init --tools opencode

# 2. 复制 schema
cp -R openspec-schemas/superpowers-schema openspec/schemas/superpowers-schema

# 3. 复制补充命令（必须！否则 verify/retrospective 没有独立命令）
cp openspec-schemas/superpowers-schema/commands/*.md .opencode/commands/

# 4. 设置默认 schema（编辑 openspec/config.yaml）
#    schema: superpowers-schema

# 5. 验证
openspec schema validate superpowers-schema
```

安装后 `.opencode/commands/` 下有 **13 个命令文件**：5 个由 `openspec init` 生成，8 个由 schema 补充。

> ⚠️ **第 3 步容易漏掉**：`openspec init` 只生成 propose / apply / archive / explore / sync 这 5 个命令。schema 的 `commands/` 目录下还有 continue / verify / status / spec / worktree / implement / debug / finish 这 8 个补充命令，不复制的话这些阶段没有独立命令可用（兜底方式用 `openspec instructions <artifact-id> --change <name> --json`）。

### 全局前置条件

| 类别 | 要求 | 验证方式 |
|---|---|---|
| OpenSpec CLI | ≥ 1.4.1 | `openspec --version` |
| schema 已装 | 校验通过 | `openspec schema validate superpowers-schema` |
| 命令文件 | 13 个 opsx-*.md | `ls .opencode/commands/opsx-*.md` |
| Superpowers 插件 | agent 会话内有 brainstorming / writing-plans / using-git-worktrees / subagent-driven-development / finishing-a-development-branch | 在 agent 会话内自查 |
| 默认 schema | `openspec/config.yaml` 的 `schema: superpowers-schema` | `grep '^schema:' openspec/config.yaml` |

---

## 二、工作流总览

```
步骤1(可选)    步骤2            步骤3-8
/opsx-explore → /opsx-propose → /opsx-apply (一条龙)
                  ↓                ├─ 步骤3 /opsx-worktree
            产出7个工件             ├─ 步骤4 /opsx-implement ← 遇bug → /opsx-debug
            (brainstorm~contract)   ├─ 步骤5 /opsx-verify
            用户批准contract        ├─ 步骤6 /opsx-continue (retro)
                  ↓                 ├─ 步骤7 /opsx-archive
              apply-ready           └─ 步骤8 /opsx-finish (PR)
```

brainstorm 阶段会自动检测变更规模，选择三种模式之一：

| 模式 | 条件 | 走哪些步 |
|---|---|---|
| Full | 新功能、架构变更、>4 文件 | 全部 8 步 |
| Hotfix | ≤4 文件、有代码逻辑、无新模块、无 API 变更 | 步骤 2 最小化 + 步骤 3-8 |
| Tweak | ≤4 文件、纯配置/文档 | 步骤 2 一句话 → 直接编辑，跳过 3-8 |

**决策规则**：不确定 Hotfix 还是 Full → 升级 Full；不确定 Tweak 还是 Hotfix → 升级 Hotfix。

---

## 三、命令清单

| 命令 | 用途 |
|---|---|
| `/opsx-propose <name>` | 创建 change + 生成全部规划工件，停在 apply-ready |
| `/opsx-apply <name>` | 执行实现（worktree → implement → verify → retro → archive → PR） |
| `/opsx-archive <name>` | 封存 change，同步 delta specs |
| `/opsx-explore` | 思考模式，不写代码，不建 change |
| `/opsx-sync <name>` | 独立同步 delta specs 到主 specs |
| `/opsx-continue <name>` | 恢复中断的 change，只创建未完成工件 |
| `/opsx-verify <name>` | 运行验证检查，产出 verify.md |
| `/opsx-status <name>` | 查询当前状态 |
| `/opsx-spec <name>` | 建 change + 跑到 specs 停（需求先行） |
| `/opsx-worktree <name>` | 创建隔离 worktree |
| `/opsx-implement <name>` | 实现（TDD + code review） |
| `/opsx-debug <name>` | 独立 bug 调查 |
| `/opsx-finish <name>` | 开 PR |

> ⚠️ **命令是连字符**：`/opsx-propose`，不是 `/opsx:propose`。

> **CLI 兜底**：没有斜杠命令的步骤，可以用 `openspec instructions <artifact-id> --change <name> --json` 让 agent 执行。

---

## 四、Full 模式完整流程

以开发一个新功能为例（贯穿示例：`add-alert-engine`）。

> Hotfix / Tweak 模式见[第五节](#五快速模式hotfix--tweak)，bug 分支见[第六节](#六bug-调查与会话恢复)，角色入口见[第七节](#七实用场景)。

### 全景表：步骤 = 命令

| 步骤 | 命令 | 输入 | 输出 |
|---|---|---|---|
| 1. 探索 | `/opsx-explore` | 问题描述 | 方案分析（不写代码，不建 change） |
| 2. 规划 | `/opsx-propose` 或 `/opsx-spec` | 用户对话 | `execution-contract.md`（含全部规划工件） |
| 3. worktree | `/opsx-apply` 或 `/opsx-worktree` | contract 已批准 | `.worktrees/<name>/` |
| 4. implement | `/opsx-apply` 或 `/opsx-implement` | `plan.md` | 代码实现 + tasks.md 打勾 |
| 5. verify | `/opsx-apply` 或 `/opsx-verify` | 代码 + tasks.md | `verify.md` |
| 6. retro | `/opsx-apply` 或 `/opsx-continue` | `verify.md`（非 FAIL） | `retrospective.md` |
| 7. archive | `/opsx-apply` 或 `/opsx-archive` | 全部完成 | delta specs 同步 + change 搬到 archive/ |
| 8. PR | `/opsx-apply` 或 `/opsx-finish` | retro + archive 完成 | PR |

> **一条龙**：`/opsx-propose` 跑步骤 2，`/opsx-apply` 跑步骤 3-8。两条命令走完全程。
>
> **细粒度控制**：`/opsx-explore` → `/opsx-propose` → `/opsx-worktree` → `/opsx-implement` → `/opsx-verify` → `/opsx-continue` → `/opsx-archive` → `/opsx-finish`，每步单独跑。
>
> **辅助命令**（不在主流程编号上）：`/opsx-status`（查状态，任何时候）、`/opsx-sync`（verify 失败补救）、`/opsx-debug`（遇 bug 分支，见[第六节](#六bug-调查与会话恢复)）。

---

### 步骤 1：探索 — `/opsx-explore`

**输入**：问题描述（如"auth 系统越来越乱"）

**输出**：方案分析（读文件、搜代码、画 ASCII 图、比较方案）

**注意**：只思考不实现，不写代码，不建 change。想清楚了再跑 `/opsx-propose`。

### 步骤 2：规划 — `/opsx-propose` 或 `/opsx-spec`

**输入**：用户对话（brainstorm 阶段一次问一个问题，提 2-3 个方案，等拍板）

**输出**：`execution-contract.md`（含全部规划工件）

`/opsx-propose` 内部自动按顺序生成 7 个工件，用户不逐步控制：

| 产出 | 输入 | 内容 |
|---|---|---|
| `brainstorm.md` | 用户对话 | 决策链 + trade-offs |
| `proposal.md` | brainstorm.md | Why / What / Capabilities |
| `design.md` | brainstorm.md | Context / Goals / Decisions / Risks |
| `specs/<capability>/spec.md` | proposal.md | 需求（SHALL/MUST）+ 场景（Scenario） |
| `tasks.md` | specs + design | checkbox 清单 |
| `plan.md` | tasks + design | TDD 微步骤（文件路径 + 测试 + commit 点） |
| `execution-contract.md` | 上述全部 | 执行契约（Intent Lock + Approval Gate） |

**contract 需要你批准**：agent 展示摘要（变更名、需求数、场景数、批次数），你确认后写入 `## Approval` 段落。没批准，后续步骤跑不了。

> **注意**：`/opsx-propose` 不传 `--schema`，要先改 `openspec/config.yaml` 默认。见[第八节实测注意点第 1 条](#八运维)。
>
> **`/opsx-spec` 替代**：只想跑到 specs 停（需求先行），用 `/opsx-spec`。后续用 `/opsx-continue` 继续 tasks → plan → contract。

### 步骤 3：worktree — `/opsx-worktree`

**输入**：contract 已批准

**输出**：`.worktrees/<name>/`（隔离工作树，新 branch + 干净 baseline）

### 步骤 4：implement — `/opsx-implement`

**输入**：`plan.md`（微步骤）

**输出**：代码实现（committed）+ tasks.md 打勾

逐 task 派 subagent 实现，每个 task 走 TDD（先写失败测试 → 实现 → 通过）+ code review。遇 bug 自动暂停（见[第六节](#六bug-调查与会话恢复)）。

### 步骤 5：verify — `/opsx-verify`

**输入**：代码 + tasks.md

**输出**：`verify.md`（✅ PASS / ⚠️ PASS WITH WARNINGS / ❌ FAIL）

- 读 `openspec/config.yaml` 的 `verify_test_command`，**真跑测试套件**（exit code 不可伪造）
- 跑 9 项检查（结构验证 / 任务完成度 / delta sync / 实现信号 / 验收锚点覆盖等）
- FAIL → 修对应问题 → 重跑 `/opsx-verify`
- 细节见 `schema.yaml` 的 verify instruction

**verify 特有前置**（`openspec/config.yaml`）：

| 配置项 | 用途 | 不声明则 |
|---|---|---|
| `verify_test_command` | 真跑测试套件的命令 | 无法实跑，tests_pass 无法判定 |
| `acceptance_doc` | 验收锚点声明 | Check 9 退化（报 N/A） |

### 步骤 6：retro — `/opsx-continue`

**输入**：`verify.md`（非 FAIL）

**输出**：`retrospective.md`（Wins / Misses / 偏差 / 经验）

### 步骤 7：archive — `/opsx-archive`

**输入**：全部完成

**输出**：delta specs 同步到主 specs + change folder 搬到 `archive/YYYY-MM-DD-<name>/`

### 步骤 8：PR — `/opsx-finish`

**输入**：retro + archive 完成

**输出**：PR（merge / keep-branch / discard 选项）

> **顺序铁律**：retro → archive → PR 顺序不能颠倒。颠倒会产出不完整 PR。

> ⚠️ **实测注意**：`/opsx-apply` 可能只跑到 implement 就停，没自动产 verify.md。手动推进：`/opsx-verify` → `/opsx-continue` → `/opsx-archive` → `/opsx-finish`。

### Full 模式速查

```bash
# 一条龙
/opsx-propose add-alert-engine     # 步骤 2（规划）
/opsx-apply add-alert-engine       # 步骤 3-8（实现→PR）

# 细粒度控制
/opsx-explore "需求描述"           # 步骤 1（探索，可选）
/opsx-propose add-alert-engine     # 步骤 2
/opsx-worktree add-alert-engine    # 步骤 3
/opsx-implement add-alert-engine   # 步骤 4
/opsx-verify add-alert-engine      # 步骤 5
/opsx-continue add-alert-engine    # 步骤 6 (retro)
/opsx-archive add-alert-engine     # 步骤 7
/opsx-finish add-alert-engine      # 步骤 8 (PR)
```

---

## 五、快速模式（Hotfix / Tweak）

Hotfix 和 Tweak 是 Full 的快速通道，跳过部分步骤。判定条件见[二节模式表](#二工作流总览)。

### 与 Full 的步骤差异

| 步骤 | Full | Hotfix | Tweak |
|---|---|---|---|
| 1. 探索 | `/opsx-explore`（可选） | 跳过 | 跳过 |
| 2. 规划 | `/opsx-propose` 完整产出 7 个工件 | `/opsx-propose` brainstorm 一句话 + contract 最小（问文件列表） | `/opsx-propose` brainstorm 一句话 → 提示直接编辑 |
| 3. worktree | `/opsx-worktree` | `/opsx-worktree` | 跳过（直接编辑） |
| 4. implement | `/opsx-implement`（TDD + review） | `/opsx-implement`（**仍走 TDD**） | 跳过 |
| 5. verify | `/opsx-verify`（9 项 + 真跑测试） | `/opsx-verify`（轻量） | `/opsx-verify`（轻量，可选） |
| 6. retro | `/opsx-continue` | 可跳（写一行理由） | 可跳 |
| 7. archive | `/opsx-archive` | `/opsx-archive` | `/opsx-archive`（可选） |
| 8. PR | `/opsx-finish` | `/opsx-finish` | `/opsx-finish` 或直接 PR |

### Hotfix 示例

场景：regex 拒绝中文名，改 1 个文件。

```bash
/opsx-propose fix-unicode-regex        # 步骤 2：brainstorm 一句话 + contract 最小
/opsx-worktree fix-unicode-regex       # 步骤 3
/opsx-implement fix-unicode-regex      # 步骤 4：TDD
/opsx-verify fix-unicode-regex         # 步骤 5：轻量验证
/opsx-archive fix-unicode-regex        # 步骤 7：retro 可跳
/opsx-finish fix-unicode-regex         # 步骤 8：PR
```

### Tweak 示例

场景：改 .editorconfig 的 max_line_length。

```bash
/opsx-propose tweak-line-length        # brainstorm 一句话 → 提示直接编辑
# 用户直接编辑 .editorconfig
/opsx-verify tweak-line-length         # 可选：轻量验证
/opsx-archive tweak-line-length        # 可选
```

或直接 PR 不走 opsx。

---

## 六、bug 调查与会话恢复

### bug 调查

bug 调查可以在**任何阶段**触发。两种入口：

**入口 1：apply 内遇 bug** — subagent 报 BLOCKED，apply 自动暂停。

**入口 2：独立触发** — 手动测试 / 线上告警发现 bug：

```bash
openspec new change investigate-oom --schema superpowers-schema
/opsx-debug investigate-oom
```

无论哪个入口，`/opsx-debug` 跑 4 阶段根因分析：

1. **根因调查**：读错误、复现、追踪数据流到源头
2. **模式分析**：找同类代码、对比差异
3. **假设与测试**：单一假设、最小验证
4. **实现**：失败测试 → 修复 → 验证。≥3 次失败 → 停止，问用户

产出 `bug-investigation.md`，Resolution 标记结果：

| Resolution | 含义 | 后续 |
|---|---|---|
| resolved | 根因找到，修复通过 | 恢复 implement |
| unresolved | 仍在调查 | 保持暂停 |
| escalated | ≥3 次失败 | 停止，等用户决策（重新想 / 简化 scope / 找外部协助） |

> **铁律**：没完成根因调查，不能提修复方案。

### 会话恢复

apply 阶段经常跨多个会话。**你什么都不用做** — agent 自动在 tasks.md 里写 checkpoint。长会话中断后重跑 `/opsx-apply`，会自动从上次断点恢复。

如果看到 "checkpoint sha missing from git history" 警告，说明 branch 被重置过，需要确认从哪里重新开始。

---

## 七、实用场景

### 7.1 按角色的典型入口

| 角色 | 入口 | 跑到哪步 | 后续 |
|---|---|---|---|
| 产品经理 | `/opsx-spec` | 步骤 2（停在 specs done） | 开发跑 `/opsx-continue` 继续 |
| 架构师 | `/opsx-propose` | 步骤 2（停在 apply-ready） | 开发跑 `/opsx-apply` |
| 开发（大功能） | `/opsx-apply` | 步骤 3-8 | 自己 |
| 开发（小功能） | `/opsx-propose` + `/opsx-apply` | Hotfix 路径（见[五节](#五快速模式hotfix--tweak)） | 自己 |
| 开发（bug） | `/opsx-debug` | [六节](#六bug-调查与会话恢复)分支 | 自己 |
| 测试 | `/opsx-verify` | 步骤 5 | 开发修 FAIL |

**verify FAIL 后修复**：

```bash
# 验收锚点没覆盖 → /opsx-implement 补实现 → /opsx-verify 重跑
# delta sync 失败 → /opsx-sync → /opsx-verify 重跑
# 测试没过 → 修代码 → /opsx-implement → /opsx-verify 重跑
```

### 7.2 按情境的辅助路径

**中途中断后恢复**：

```bash
/opsx-status add-alert-engine         # 查状态
openspec list                          # 列出所有 active changes
```

然后从断点继续：planning 断了 → `/opsx-continue`；apply 断了 → `/opsx-apply` 或 `/opsx-implement`；verify/retro 没跑 → `/opsx-verify` → `/opsx-continue`。

**想先探索**：见[四章步骤 1](#步骤-1探索--opsx-explore)。

**验证全项目状态**：

```bash
openspec validate --all --json
openspec status --change <name> --json
openspec schemas
```

**放弃一个 change**：清理 workspace（删 worktree、决定 branch 去留）→ change folder 处理（`/opsx-archive` 封存 / 留在 changes/ / 直接删除）→ 写一句放弃原因即可。

---

## 八、运维

### 实测注意点

1. **`/opsx-propose` 不传 `--schema`**：要先改 `openspec/config.yaml` 默认，或先手动 `openspec new change <name> --schema superpowers-schema` 再跑 `/opsx-propose <name>`。
2. **AGENTS.md**：OpenCode 用 `AGENTS.md` 作为 instruction 文件。
3. **不要绕过 front-door**：所有产出必须落在 `openspec/changes/<name>/`，不要写到 `docs/superpowers/specs/`。

### 什么时候不建 change

直接开 PR，不走 opsx：bug fix（恢复行为不改合约）、test backfill、linter 调整、依赖升级、文档/typo、config 微调。

**红线**：触及对外 API 合约、跨系统介接、DB schema、合规边界，或行为是新增/改变 → 必须建 change。

### Schema 切换

schema 在 change 创建时锁定。改项目默认：

```yaml
# openspec/config.yaml
schema: superpowers-schema   # 或 spec-driven
```

单次指定：

```bash
openspec new change my-feature --schema spec-driven
/opsx-propose my-feature   # 继续已存在的 change
```

### 健康检查

1. `openspec --version` → 1.4.1 或更高
2. `openspec schemas` → 列出 superpowers-schema
3. `openspec schema validate superpowers-schema` → 通过
4. agent 会话内有：brainstorming / writing-plans / using-git-worktrees / subagent-driven-development / finishing-a-development-branch
5. `.opencode/commands/` 下有 13 个 opsx-*.md
6. `.opencode/skills/openspec-*/` 下有 SKILL.md 文件

### 升级

```bash
rm -rf openspec/schemas/superpowers-schema
cp -R openspec-schemas/superpowers-schema openspec/schemas/superpowers-schema
cp openspec-schemas/superpowers-schema/commands/*.md .opencode/commands/
openspec schema validate superpowers-schema
```

已归档的 change 不受影响。进行中的 change 如果 plan.md 已存在但 contract 不存在，`/opsx-continue` 会自动生成。

