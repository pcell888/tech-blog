---
title: "Forge：用 Guardrails 把 8B 本地模型的 Agent 能力从 53% 提升到 86%"
date: 2026-06-16
draft: false
tags:
  - AI
  - Agent
  - Guardrails
  - 开源
---

## 一、引子

在 AI Agent 开发中有一个公认的困境：**小模型听话但不够聪明，大模型聪明但太贵（或者根本跑不起来）。**

你如果买不起 H100，就只能用 Ollama 跑 7B/8B 模型做 Agent。然后你会发现：本地模型在 function calling 上经常出幺蛾子——参数格式不对、步骤跳了、遇到错误就崩。不是模型不好，是**没有人帮它兜底。**

Forge 就是来解决这个问题的。

这是一个 Python 框架，专为**自托管 LLM 的 tool-calling 场景设计**，核心是一套 Guardrails（护栏）机制。它不是取代你的 Agent 框架，而是在你的模型背后加一层"智能兜底"——当模型出错时，自动修复、重试、强制执行流程。

GitHub 地址：https://github.com/antoinezambelli/forge
Stars：885（2026.05），Python 项目，MIT 许可证
已发表 IEEE 论文：DOI 10.1145/3786335.3813193

---

## 二、Forge 是什么

官方描述：*"A reliability layer for self-hosted LLM tool-calling."*

翻译成人话：**你有一个 8B 的本地模型，它经常在 tool-calling 上犯错，Forge 帮你兜底。**

它支持 3 种使用方式：

### 1. WorkflowRunner（最完整）
定义 tools、选后端、跑完整的 agent 循环。Forge 帮你管理 system prompt、tool 执行、上下文压缩、Guardrails 全套。

### 2. Guardrails 中间件（最灵活）
你用自己的编排循环，只接入 Forge 的 guardrails 层——验证响应、救援格式错误的 tool call、强制执行必要的步骤。见 [examples/foreign_loop.py](https://github.com/antoinezambelli/forge/blob/main/examples/foreign_loop.py)。

### 3. Proxy Server（最省事）
跑一个 OpenAI 兼容的代理服务器，放在你的客户端（opencode、Continue、aider 等）和本地模型之间。客户端啥都不用改，Proxy 自动注入 guardrails——客户端以为自己用的是个更聪明的模型。

```bash
python -m forge.proxy --backend-url http://localhost:8080 --port 8081
```

**支持的后端：** Ollama、llama-server（llama.cpp）、Llamafile、Anthropic

---

## 三、Guardrails 的 5 道防线

Forge 的 guardrails 不是"一个东西"，而是**5 层可组合的机制**：

### 1. Rescue Parsing（救援解析）

模型输出的 tool call 格式不对？Forge 不直接抛错，而是尝试多层次解析：
- 标准的 JSON 解析
- 修复常见语法错误（缺少引号、多余的逗号等）
- 如果完全无法解析，**触发 rescue 循环**——把解析失败和原始输出塞回 prompt，让模型重试

### 2. Retry Nudges（重试提示）

当模型输出的内容不完整或不符合预期时，Forge 不是简单地说"重试"，而是给出 **nudge（提示）**——指出具体哪里不对、应该怎么改。比如：

> "You called `get_weather` but the 'city' parameter is missing. The available tools and their required parameters are: ..."

### 3. Step Enforcement（步骤强制）

Agent 经常跳步——明明需要先查数据库再算结果，它直接给出答案。Forge 的 **StepEnforcer** 维护一个步骤追踪器（StepTracker），检查每个时间点该做什么步骤，没做就 push 回去。

### 4. Error Recovery（错误恢复）

工具执行报错了怎么办？大多数 Agent 直接崩溃。Forge 把错误信息封装后塞回上下文，让模型重试或换方案。

### 5. Context Management（上下文管理）

本地模型的上下文窗口有限（通常 8K-32K）。Forge 实现了分层压缩策略：
- **TieredCompact**：保留最近的 N 轮对话，对中间内容做摘要压缩
- **SlidingWindowCompact**：滑动窗口截断
- 支持 VRAM 感知的预算控制

---

## 四、数据：Guardrails 的效果有多夸张

Forge 跑了一套 26 个场景的评测（OG-18 基础 + 8 个高级推理场景），覆盖了 Agent 常见的各种翻车点：工具选择、条件路由、顺序推理、错误恢复、数据缺口恢复、参数转换、有状态场景等等。

### 最亮眼的一组：Ministral-3 8B

| 配置 | 综合得分 | 提升 |
|------|---------|------|
| Bare（无 Guardrails） | 52.7% | — |
| Reforged（全套 Guardrails） | **86.5%** | **+33.8pp** |

一个 8B 的量化模型，仅仅加了 Guardrails，就从勉强及格变成了"能用"。

### 再看神仙打架——Anthropic 系列

| 模型 | Bare | Reforged | 提升 |
|------|------|----------|------|
| Claude Opus 4 | 87.9% | **99.2%** | +11.3pp |
| Claude Sonnet 4 | 85.1% | **98.4%** | +13.3pp |
| Claude Haiku 4.5 | 46.5% | **94.5%** | **+48.0pp** |

Haiku 的提升最夸张——从几乎不及格到 94.5%，说明 Guardrails 对小模型的价值远大于大模型。而且 Haiku 本身是 Anthropic 最便宜的模型，加上 Guardrails 后能力逼近 Opus。

### 其他模型的数据

| 模型/后端 | Bare | Reforged | 提升 |
|-----------|------|----------|------|
| Ministral-3-14B Q4 (LS/N) | 34.1% | 84.7% | +50.6pp |
| Ministral-3-8B Reasoning Q8 (LS/N) | 45.9% | 79.6% | +33.7pp |
| Mistral-7B v0.3 Q8 (LS/P) | 17.8% | 46.1% | +28.3pp |
| Mistral-7B v0.3 Q8 (LS/P) bare→reforged | 17.8% | 46.1% | +28.3pp |
| Meta-Llama-3.1-8B Q4 (LF/P) | 36.1% | 51.2% | +15.1pp |
| Mistral-Nemo 12B (OL/N) | 0% | 34.2% | +34.2pp |

**注意：** Mistral-Nemo 12B 在 Ollama 上 bare 模式得分为 0%（完全跑不起来），加了 Guardrails 后到了 34.2%。这就是 Guardrails 的"起死回生"效果。

### 消融实验：哪个 Guardrail 最管用？

从数据看，去掉不同组件的影响：
- **去掉 Rescue 循环**：得分下降最明显（约降 15-25pp）
- **去掉 Nudge**：影响其次（约降 10-15pp）
- **去掉 Step Enforcement**：影响的场景比较有限（约降 5-10pp）

结论：**Rescue Parsing 是最关键的单个组件，但组合使用效果最好。**

### 26 个场景中最难的和最容易的

最容易被 Guardrails 拉满的：
- `error_recovery`：bare 0% → reforged 100%（从完全不会到满分）
- `data_gap_recovery_extended`：bare 0% → reforged 96%
- `relevance_detection`：bare 100% → reforged 100%（本来就不需要修）

最难啃的（加了 Guardrails 依然偏低）：
- `argument_transformation`（某些后端加不上去）
- `tool_selection`（小模型依然有困难）

---

## 五、一个特别聪明的设计：synthetic respond tool

在 Proxy 模式下，Forge 会自动注入一个 `respond` 虚拟工具：

模型不走文本输出，而是调用 `respond(message="...")`，**始终保持在 tool-calling 模式中**。Forge 的整个 Guardrails 栈只对 tool call 生效，如果模型直接输出文本，就绕过 Guardrails 了。

`respond` 调用在返回给客户端前被剥离——客户端看到的是 `finish_reason: "stop"` 的正常响应，完全不知道背后有这个工具存在。

项目作者的原话：*"对于 ~8B 的小模型，你不能信任它们在文本和 tool call 之间做正确选择，引导它们使用 tool 是必须的。"*

---

## 六、架构与用法

### 安装

```bash
pip install forge-guardrails
pip install "forge-guardrails[anthropic]"   # 如果需要 Anthropic 后端
```

### 快速上手指南

**最简单的——Proxy 模式（推荐先试这个）：**

1. 启动一个 llama-server（或其他后端）
2. 跑 Proxy：
   ```bash
   python -m forge.proxy --backend-url http://localhost:8080 --port 8081
   ```
3. 把你的客户端 API base 指向 `http://localhost:8081/v1`
4. 完事。Guardrails 自动生效。

**WorkflowRunner 模式：**

```python
from forge import Workflow, ToolDef, WorkflowRunner, OllamaClient

workflow = Workflow(
    name="weather",
    tools={...},  # 定义你的工具
    required_steps=[],  # 必选步骤
    terminal_tool="get_weather",
)

runner = WorkflowRunner(
    client=OllamaClient(model="ministral-3:8b-instruct-2512-q4_K_M"),
    context_manager=ContextManager(budget_tokens=8192)
)
await runner.run(workflow, "What's the weather in Paris?")
```

### 项目结构一览

```
src/forge/
  core/           # 工作流引擎、推理循环、SlotWorker
  guardrails/     # 核心：nudge、response_validator、step_enforcer、error_tracker
  clients/        # 后端客户端（Ollama、llama.cpp、Llamafile、Anthropic）
  context/        # 上下文管理（分层压缩、滑动窗口、硬件检测）
  prompts/        # nudge 模板
  tools/          # synthetic respond tool
  proxy/          # Proxy 服务器
```

865 个单元测试（无需 LLM 后端），代码质量相当扎实。

---

## 七、局限性与适用场景

### 适合的场景

- **自托管/本地部署的 Agent 系统**——你有 GPU，但买不起 API
- **小模型（7B-14B）做 function calling**——加 Guardrails 后效果翻倍
- **对 Token 成本敏感的批量任务**——Q8 量化 + Guardrails = 接近 API 品质但零 API 费用
- **想用廉价模型跑高可靠性任务**——Haiku + Guardrails = 94.5%，绝对够用

### 不适合的场景

- **纯聊天/问答**——不是它的场景，建议用原生聊天
- **超长复杂推理链（50+ 步）**——Guardrails 会增加 Token 消耗，上下文管理压力大
- **已经有成熟 API 方案且不差钱**——直接 Opus 就 99.2%，不需要 Guardrails

### 代价

- Guardrails 会增加推理时间（rescue 循环会让模型多跑几次）
- Token 消耗增多（每次 rescue 和 nudge 都会增加上下文）
- 不是所有模型都能救——Mistral-7B 加了 Guardrails 也只有 46%，先天能力不足

---

## 八、总结

Forge 的价值主张非常清晰：

> **模型能力不够？不要换模型，加 Guardrails。**

它用 5 层可组合的兜底机制，把一个 53% 的 8B 模型提升到 86%，把 46% 的 Haiku 提升到 94%。IEEE 论文背书，865 个单元测试，代码质量过硬。

在当前"人人都在追大模型"的风气下，Forge 的思路显得格外务实：**不是所有问题都需要用更大的模型来解决，有时候只是需要更好的工程。** 对于预算有限、需要本地部署、或者对 Token 成本敏感的团队来说，这是一个非常值得关注的项目。

---

*本文写作时间：2026 年 5 月 20 日*
*数据来源：[GitHub - antoinezambelli/forge](https://github.com/antoinezambelli/forge)*
*论文：Zambelli, A. Forge: A Reliability Layer for Self-Hosted LLM Tool-Calling. DOI: [10.1145/3786335.3813193](https://doi.org/10.1145/3786335.3813193)*
