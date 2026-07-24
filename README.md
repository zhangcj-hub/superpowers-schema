# superpowers-schema

> OpenSpec × Superpowers 的桥接层：把工件治理（what）和执行技能（how）在 prompt 层焊在一起。

这是一份带立场的 [OpenSpec](https://github.com/Fission-AI/OpenSpec) schema，把 [Superpowers](https://github.com/obra/superpowers) 的技能挂到 spec-driven 流程上。它新增了 **execution-contract** 桥接工件、**verify** 决策点、**retrospective** 复盘工件、**bug-investigation** 旁路，外加 Hotfix/Tweak 快速通道，以及跨会话恢复用的 checkpoint 协议。

**仅支持 OpenCode。** schema 写死了 OpenCode 的 skill loader 和命令命名，其他平台不适用，请改用内置的 `spec-driven` schema。

| | |
|---|---|
| 版本 | 1.2.0（[`superpowers-schema/VERSION`](./superpowers-schema/VERSION)） |
| 许可证 | MIT © zhangcj-hub |
| 依赖 | OpenSpec CLI ≥ 1.4.1、Superpowers 插件、OpenCode |
| 详细手册 | [docs/guide.md](./docs/guide.md)（简体中文，v1.2.0） |

---

## 为什么需要

`spec-driven` 只管「一个 change 该产出哪些工件」，不管「agent 怎么执行这些工件」。Superpowers 带来了严谨性（brainstorming、TDD、git worktree、subagent 派发、code review、branch finishing），但没有工件生命周期。这份 schema 把两者拼到一起。

工件治理定义了完整生命周期：brainstorm → proposal → design → specs → tasks → plan → contract → apply → verify → retrospective。

执行技能在每个步骤**强制调用**，不是凭记忆复述。每次 skill 调用会载入权威的 `SKILL.md`，并产生一个 `skill-call` 审计标记，评估流水线（`ai-eval`）依赖它判断技能是否真的被使用。

效果：每个 change 都在契约下规划，在隔离 worktree 内用 TDD + code review 实现，对外部验收锚点验证，最后用证据优先的复盘收尾，整个过程能跨 context compression 恢复。

---

## 核心特性

- **Execution contract**：把规划工件压缩成一份需用户批准的交付物，内含 **Intent Lock**（内容指纹）和 **Approval Gate**。没批准就不允许实现。
- **Verify 决策点（DP-6）**：9 项检查，包括真跑测试套件（exit code 无法伪造）、按 spec scenario 抽查 task、把实现追溯到 `openspec/config.yaml` 里的外部验收锚点。
- **Retrospective**：证据优先，§0 定量前置加上 §1–§6 分析，配 promote-candidates 清单跨周期传承。
- **Bug investigation**：条件旁路，4 阶段根因调查，铁律是「没有根因就不准提修复」。≥3 次失败就升级，不许继续猜。
- **Hotfix / Tweak 快速通道**：小改动跳过规划工件，但 Hotfix 仍走 TDD，Tweak 直接编辑。
- **8 态状态机**：由工件完成度推导，`exploring → specifying → bridging → approved-for-build → executing → debugging → closing → abandoned`。
- **Checkpoint 协议**：`tasks.md` 里以 HTML 注释记录绑定到 commit SHA 的 checkpoint，中断的 `/opsx-apply` 从上一个完成的 task group 恢复。
- **防软化设计**：验收语句只存在 `config.yaml` 里（单一来源），contract 只引用锚点 ID，change 没法悄悄弱化需求。

---

## 仓库结构

```
install.ps1                  # Windows 一键安装脚本（PowerShell 7+）
superpowers-schema/
├── schema.yaml              # schema 定义（工件 + apply 阶段，机器可读）
├── VERSION                  # 1.2.0
├── commands/                # 8 个补充斜杠命令定义
│   ├── opsx-continue.md     # 恢复中断的 change / 产出 retrospective
│   ├── opsx-debug.md        # 独立 bug 调查
│   ├── opsx-finish.md       # 开 PR（branch finishing）
│   ├── opsx-implement.md    # 通过 subagent 执行（TDD + code review）
│   ├── opsx-spec.md         # 建 change，跑到 specs 停（需求先行）
│   ├── opsx-status.md       # 查询当前状态
│   ├── opsx-verify.md       # 跑 9 项检查，产出 verify.md
│   └── opsx-worktree.md     # 创建隔离 git worktree
└── templates/               # 10 个工件模板
    ├── brainstorm.md
    ├── bug-investigation.md
    ├── design.md
    ├── execution-contract.md
    ├── plan.md
    ├── proposal.md
    ├── retrospective.md
    ├── spec.md
    ├── tasks.md
    └── verify.md
docs/
└── guide.md                 # 完整使用手册（简体中文）
```

---

## 环境要求

| 类别 | 要求 | 验证方式 |
|---|---|---|
| OpenSpec CLI | ≥ 1.4.1 | `openspec --version` |
| schema 已装 | 校验通过 | `openspec schema validate superpowers-schema` |
| 命令文件 | 13 个 `opsx-*.md` | `ls .opencode/commands/opsx-*.md` |
| Superpowers 插件 | brainstorming、writing-plans、using-git-worktrees、subagent-driven-development、systematic-debugging、finishing-a-development-branch | agent 会话内自查 |
| 默认 schema | `openspec/config.yaml` 里 `schema: superpowers-schema` | `grep '^schema:' openspec/config.yaml` |

---

## 安装

### Windows（推荐）

用仓库自带的 [`install.ps1`](./install.ps1)，一条命令完成 init + 复制 schema + 复制命令 + 设置默认 schema + 校验。

```powershell
# 在本仓库根目录运行
.\install.ps1 -ProjectPath D:\code\my-app

# 升级（覆盖旧版本，跳过 y/N 确认）
.\install.ps1 -ProjectPath D:\code\my-app -Upgrade

# 不带参数则交互式询问目标路径
.\install.ps1
```

脚本会自动：

1. 检查 openspec CLI ≥ 1.4.1
2. 若目标项目未初始化 OpenSpec，自动跑 `openspec init --tools opencode`
3. 复制 schema 到 `openspec/schemas/superpowers-schema`
4. 复制 8 个补充命令到 `.opencode/commands/`
5. 设置 `openspec/config.yaml` 的 `schema: superpowers-schema`
6. 运行 `openspec schema validate` 校验

> ⚠️ **脚本需要 PowerShell 7+**（开源跨平台版，不是 Windows 自带的 Windows PowerShell 5.1）。未安装时任选一种：
>
> | 方式 | 命令 / 链接 |
> |---|---|
> | winget | `winget install Microsoft.PowerShell` |
> | MSI 安装包 | [GitHub Releases](https://github.com/PowerShell/PowerShell/releases)（选 `PowerShell-7.x.x-win-x64.msi`） |
> | .NET 全局工具 | `dotnet tool install -g PowerShell` |
> | Scoop | `scoop install pwsh` |
>
> 验证：`pwsh -Command '$PSVersionTable.PSVersion'` 应 ≥ 7.0。
>
> 如遇执行策略限制：`pwsh -ExecutionPolicy Bypass -File .\install.ps1`。

### 通用（手动）

适用 macOS / Linux / 不用脚本的 Windows。等价于 `install.ps1` 的逐步版本。

```bash
# 1. 在项目里初始化 OpenSpec（OpenCode 模式）
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

> ⚠️ **第 3 步容易漏掉。** `openspec init` 只生成 5 个命令（propose / apply / archive / explore / sync），schema 的 `commands/` 还有 8 个补充命令（continue / verify / status / spec / worktree / implement / debug / finish）。不复制的话这些阶段没有斜杠命令可用，兜底方式是 `openspec instructions <artifact-id> --change <name> --json`。

### 升级

```bash
# 通用
rm -rf openspec/schemas/superpowers-schema
cp -R openspec-schemas/superpowers-schema openspec/schemas/superpowers-schema
cp openspec-schemas/superpowers-schema/commands/*.md .opencode/commands/
openspec schema validate superpowers-schema
```

```powershell
# Windows（PowerShell 7+）
.\install.ps1 -ProjectPath D:\code\my-app -Upgrade
```

已归档的 change 不受影响。进行中的 change 如果缺工件，下一次 `/opsx-continue` 会自动补齐。

---

## 工作流总览

```
（可选）           规划                  apply（一条龙或细粒度）
/opsx-explore → /opsx-propose → /opsx-apply ─┬─ /opsx-worktree
                  │                            ├─ /opsx-implement ←─ bug ─→ /opsx-debug
        7 个规划工件                            ├─ /opsx-verify
        用户批准 contract                       ├─ /opsx-continue（retrospective）
                  │                             ├─ /opsx-archive（同步 delta specs）
              apply-ready                       └─ /opsx-finish（PR）
```

**一条龙**：`/opsx-propose <name>` 跑规划，`/opsx-apply <name>` 跑 implement → verify → retro → archive → PR。

**细粒度**：每步都有独立命令，见下表。

---

## 命令清单

共 13 个斜杠命令，5 个由 `openspec init` 生成，8 个由本 schema 补充。

| 命令 | 用途 |
|---|---|
| `/opsx-explore` | 思考模式，分析方案，不写代码，不建 change |
| `/opsx-propose <name>` | 建 change + 生成全部规划工件，停在 apply-ready |
| `/opsx-spec <name>` | 建 change，跑到 specs 停（需求先行） |
| `/opsx-apply <name>` | 执行实现（worktree → implement → verify → retro → archive → PR） |
| `/opsx-worktree <name>` | 创建隔离 git worktree |
| `/opsx-implement <name>` | 通过 subagent-driven-development 执行任务（TDD + code review） |
| `/opsx-debug <name>` | 独立 bug 调查（4 阶段根因） |
| `/opsx-verify <name>` | 跑 9 项检查，产出 verify.md |
| `/opsx-continue <name>` | 恢复中断的 change，只补未完成的工件 |
| `/opsx-sync <name>` | 独立同步 delta specs 到主 specs |
| `/opsx-archive <name>` | 封存 change，同步 delta specs，搬到 `archive/` |
| `/opsx-finish <name>` | 开 PR（merge / keep-branch / discard） |
| `/opsx-status <name>` | 查询当前状态 |

> 命令是连字符：`/opsx-propose`，不是 `/opsx:propose`。

---

## 工件与生命周期

Full 模式产出 7 个规划工件，外加 2 个 apply 后工件（bug-investigation 是条件旁路）：

```
brainstorm → proposal → design → specs → tasks → plan → execution-contract
                                                            │
                                                            ▼  （用户批准）
                                                          apply
                                                            │
                                              ┌─────────────┼─────────────┐
                                              ▼             ▼             ▼
                                          implement      verify      retrospective
                                              │             │
                                              ▼             ▼
                                     (bug-investigation   archive → PR
                                      旁路，仅当 subagent
                                      报 BLOCKED 时触发)
```

| 工件 | 由什么产出 | 用途 |
|---|---|---|
| `brainstorm.md` | 用户对话 | 决策链 + trade-offs（原始捕获） |
| `proposal.md` | brainstorm.md | Why / What / Capabilities |
| `design.md` | brainstorm.md | Context / Goals / Decisions / Risks / Migration |
| `specs/<cap>/spec.md` | proposal.md | 需求（SHALL/MUST）+ 场景（WHEN/THEN） |
| `tasks.md` | specs + design | checkbox 清单（按格式解析进度） |
| `plan.md` | tasks + design | TDD 微步骤（文件路径 + 测试 + commit 点） |
| `execution-contract.md` | 上述全部 | 压缩交付物：Intent Lock + Approval Gate |
| `verify.md` | 实现 + tasks | 9 项检查 + Overall Decision（PASS / WARNINGS / FAIL） |
| `retrospective.md` | verify.md（非 FAIL） | 证据优先的 Wins / Misses / 偏差 / 学习 |
| `bug-investigation.md` | （条件触发） | 4 阶段根因报告 + Resolution |

---

## 工作流模式

`brainstorm` 自动判断变更规模，从三种模式里选一种：

| 模式 | 触发条件 | 走哪些步 |
|---|---|---|
| **Full**（默认） | 新功能、架构变更、>4 文件 | 全部 8 步 |
| **Hotfix** | ≤4 文件、无新模块、无 API/schema 变更、有代码逻辑 | 最小 contract + worktree + implement（仍走 TDD）+ 轻量 verify |
| **Tweak** | ≤4 文件、纯配置/文档、无代码逻辑 | 一行 brainstorm → 直接编辑，跳过工件 |

**决策规则**：不确定 Hotfix 还是 Full 就升级 Full，不确定 Tweak 还是 Hotfix 就升级 Hotfix。用户也可以显式声明（「这是 hotfix」「用 full workflow」）。

---

## 验证：9 项检查

Full 模式下 `/opsx-verify` 在 archive 之前跑：

| # | 检查项 | 是否阻塞 |
|---|---|---|
| 1 | 结构验证（`openspec validate --all`） | ✅ |
| 2 | 任务完成度（tasks.md 全部 `- [x]`） | ✅ |
| 3 | 任务抽查（对照 spec scenario，反自证） | warning |
| 4 | delta spec 同步状态 | ✅ |
| 5 | design/specs 一致性 | warning |
| 6 | 实现信号（commit、无未暂存文件） | ✅ |
| 7 | 前门路由泄漏检测 | warning |
| 8 | 延期 dogfood 与自动化测试等价性 | 跳过则 ✅ |
| 9 | 验收锚点覆盖（经 milestone 追溯到 `config.yaml`） | ✅ |

**外加 Step 4.0**：测试套件**真跑**，通过 `openspec/config.yaml` 的 `verify_test_command`。exit code 无法伪造，`tests_pass: unknown` 不再被接受。

**决策点 DP-6** 按 Overall Decision 路由：
- ✅ PASS 或 ⚠️ PASS WITH WARNINGS → 进 retrospective
- ❌ FAIL → 停。每项阻塞检查都会指明根因工件和补救命令

---

## 设计说明

- **为什么不用 `executing-plans`？** 它不会传递性激活 TDD 和 code review，丢了 Superpowers 的价值。本 schema 强制用 `subagent-driven-development`，它会把这两者一起带出来。
- **Skill 调用是强制的，不是可选。** 每个工件的 instruction 都有 `MANDATORY SKILL INVOCATION` 段落。凭记忆复述技能就是流程违规，`skill-call` 标记不会出现在 prompts archive 里。
- **验收锚点在 change 内不可变。** 一个功能 change 不准改 `config.yaml` 的 `acceptance_doc` 段，那是项目级基础设施。要改得开一个独立的 acceptance-baseline change。
- **会话恢复。** `tasks.md` 里的 checkpoint HTML 注释能扛过 context compression，`/opsx-apply` 从上一个完成的 task group 恢复。checkpoint SHA 缺失会警告用户 branch 被重置过。

---

## 什么时候不建 change

直接开 PR、不走 opsx 的情况：恢复既有行为的 bug 修复、补测试、linter 调整、依赖升级、文档/typo、config 微调。

**红线**：触及对外 API 合约、跨系统介接、DB schema、合规边界，或行为是新增/改变，就必须建 change。

---

## 文档

- [**docs/guide.md**](./docs/guide.md)：完整使用手册（简体中文，v1.2.0），包含安装、Full 模式完整流程、Hotfix/Tweak 示例、bug 调查、会话恢复、按角色的入口、运维注意点。
- [`superpowers-schema/schema.yaml`](./superpowers-schema/schema.yaml)：schema 定义（工件、apply 阶段、状态机），机器可读。
- [`superpowers-schema/templates/`](./superpowers-schema/templates/)：工件模板。
- [`superpowers-schema/commands/`](./superpowers-schema/commands/)：斜杠命令定义。

---

## 相关

- [obra/superpowers](https://github.com/obra/superpowers)：Superpowers skill 源。
- [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)：OpenSpec。
- [OpenSpec PR #970](https://github.com/Fission-AI/OpenSpec/pull/970)：驱动本设计的原始 review 线程。

## 许可证

[MIT](./LICENSE) © zhangcj-hub
