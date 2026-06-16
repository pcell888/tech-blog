---
title: "Agent 方向全面调研报告"
date: 2026-06-16
draft: false
tags:
  - AI
  - Agent
  - 调研
  - 架构
  - 开源
---

> 调研时间: 2026-05-27
> 调研范围: Agent Harness / Proactive AI / Multi-Agent / Agent Infra + OpenCode & Hermes 实现原理分析 + 简易版实现建议

---

## 一、Agent Harness（评估框架 / 基准测试）

### 1.1 评估循环范式

所有动态 Benchmark 共享一个交互式评估循环：

```
环境初始化 (Sandbox/Docker/Browser)
  → 任务注入 (Goal + Success Criteria)
  → 交互循环 (Agent 观察 → 行动 → 环境反馈)
  → 终止 (步数限制 / 成功标记 / Agent 提交答案)
  → 评分 (最终状态 vs Ground Truth)
```

### 1.2 代表性 Benchmark

| Benchmark | 领域 | 评估方式 | 核心特点 |
|-----------|------|----------|----------|
| **SWE-bench** (Princeton) | 代码修复 | Docker 沙箱 + 单元测试 | clone repo → 读 issue → 修改 → diff 通过全部测试 |
| **WebArena** (CMU) | 网页操作 | Browser 自动化 | 目标驱动 (如"买衬衫")，最终 DOM 状态匹配 |
| **GAIA** (Meta/HF) | 通用推理 | 精确匹配答案 | 多步推理 + 工具调用，L1-L3 难度 |
| **BFCL** (Berkeley) | 函数调用 | AST 匹配 | 给定函数列表 + query，输出函数名+参数 |
| **TAU-bench** (Replit/Anthropic) | 客服场景 | 任务成功率 + Slot 准确率 | 细粒度 slot 级奖励 + 整体成功 |
| **AgentBench** (清华) | 多领域 | 聚合成功率 | 8 个不同环境 (OS, SQL, Web, 游戏等) |
| **Cybench** (Scale/METR) | 网络安全 | Flag 提交 | 完整 Linux VM + CTF 挑战 |
| **AndroidArena** (UIUC) | 手机操作 | 动作匹配 + 任务成功 | 截图输入 → tap/swipe/type |

### 1.3 评估框架工具

- **Inspect** (UK AISI / DeepMind) — 最现代的 Agent 评估框架。组件: Dataset → Solver → Scorer。原生 Docker 沙箱、工具定义、自定义评分
- **LangSmith / Braintrust** — 可观测性 + 评估平台，适合自定义评估轨迹
- **Promptfoo** — CLI 优先，prompt 对比、红队测试、CI 集成
- **DeepEval** — LLM 单元测试框架，丰富的评估指标

### 1.4 关键评估技术

- 结果导向评分（只看最终状态，不看路径）
- 功能性正确性（通过外部测试套件）
- 精确匹配 / AST 匹配
- Slot 准确率（约束满足）
- 沙箱化执行（Docker/VM/Emulator）
- 轨迹追踪（步骤数、API 成本、动作多样性）

---

## 二、Proactive AI（主动式 AI）

### 2.1 主动 vs 被动 Agent

| 被动 Agent | 主动 Agent |
|-----------|-----------|
| 等待触发 (用户输入/API调用) | 内部持续循环，基于内部状态主动行动 |
| "你想让我做什么？" | "我认为下一步应该做这个" |
| 单轮/无状态 | 持久记忆、目标导向、自我规划 |
| 容易控制 | 难以对齐，可能偏离用户意图 |

### 2.2 核心框架

**Voyager** (NVIDIA, 2023)
- 架构: LLM + Skill Library (向量 DB) + Curriculum Agent + Iteration Agent
- 主动性: Curriculum Agent 自动提出下一个探索任务; 失败后自动反思修复
- 关键: 纯代码技能库持续增长，base LLM 不动

**Generative Agents** (Stanford, 2023)
- 架构: Memory Stream → Retrieval → Reflection → Daily Planning
- 主动性: Agent 根据 persona 和记忆自发生成日计划，可主动打断自己的日程
- 关键: 主动行为是涌现的，源自丰富的记忆和反思

**Reflexion** (Shinn et al., 2023)
- 架构: Actor + Evaluator + Episodic Memory + Self-Reflection
- 主动性: Agent 失败后自动反思原因，下次加载反思作为上下文
- 关键: 轻量级自我改进，无需权重更新

### 2.3 目标设定机制

| 机制 | 代表 | 工作原理 |
|------|------|----------|
| 自动化课程 | Voyager | 独立 LLM 根据技能库评估，提出下一个最有用的任务 |
| 好奇心/新颖性 | Voyager | Agent 因探索新状态而获得"奖励" |
| 社交上下文 | Stanford Agents | 从 persona 和社会记忆中涌现目标 |
| 失败驱动 | Reflexion | 持续失败产生反思轨迹，成为新目标 |
| 任务分解 | AutoGPT 等 | 模糊指令由 LLM 规划器分解为子目标 |

### 2.4 记忆架构

- **技能库 (程序记忆)**: Voyager 的向量 DB 代码库，单调增长
- **记忆流 (情景记忆)**: Stanford 的时间线日志，按近期性/重要性/相关性检索
- **反思树**: Stanford 定期从记忆流中综合高级洞察
- **情景缓冲**: Reflexion 的完整交互轨迹 + 失败总结

---

## 三、Multi-Agent 系统

### 3.1 主流框架对比

| 框架 | 语言 | 协调模式 | 核心特点 | 适用场景 |
|------|------|---------|---------|---------|
| **LangGraph** | Python | 有向状态图 | 强类型状态、checkpoint、streaming、human-in-loop | 复杂非线性工作流 |
| **CrewAI** | Python | 角色分层 | Role/Goal/Backstory/Tools 抽象，Sequential/Hierarchical Process | 快速原型，角色扮演 |
| **AutoGen** (MS) | Python | 对话驱动 | GroupChat + Manager，speak-order，nested chats | 对话式代码生成、讨论 |
| **Agno** | Python | 分层委托 | Team (manager delegator) + Workflow，多模态 | 多模态 API 编排 |
| **MetaGPT** | Python | SOP 瀑布 | 角色(PM/架构/工程/QA)通过消息池 pub/sub 协作 | 结构化软件工程 |
| **ChatDev** | Python | Chat Chain | CEO/CTO/程序员/测试按阶段流水线沟通 | 从 prompt 生成可执行代码 |
| **OpenDevin** | Python | 沙箱 ACI | Agent-Computer Interface，bash/browser/filesystem | 类 SWE-bench 代码任务 |

### 3.2 六种协调模式

1. **顺序/流水线** (CrewAI, ChatDev) — 任务按顺序执行，前一输出是后一输入
2. **分层管理** (CrewAI, Agno) — Manager agent 分配任务给子 agent
3. **群聊 / 轮次** (AutoGen) — GroupChatManager 控制发言顺序
4. **条件图路由** (LangGraph) — 节点按条件边跳转
5. **Pub/Sub 消息池** (MetaGPT) — 角色订阅感兴趣的消息类型
6. **环境沙箱** (OpenDevin) — 所有 agent 操作同一个沙箱环境

### 3.3 关键设计考量

- **状态管理**: LangGraph 用 TypedDict + checkpoint; AutoGen 用对话历史; MetaGPT 用共享消息池
- **通信模式**: 显式图边、消息队列、角色 channel、共享状态
- **可观测性**: LangSmith trace、CrewAI callback、AutoGen logging
- **扩展性**: 随着 agent 数量增加，协调复杂度 O(n²)

---

## 四、Agent Infra（基础设施）

### 4.1 协议层

| 协议 | 开发商 | 用途 | 现状 |
|------|--------|------|------|
| **MCP** (Model Context Protocol) | Anthropic | Agent-to-Tools 连接标准 | 事实标准，Goose/Cursor/Zed/Hermes 全支持 |
| **A2A** (Agent-to-Agent) | Google | Agent 间通信 (2025.4 发布) | 新兴标准 |
| **ACP** (Agent Communication Protocol) | 社区 | 通用 agent 通信 | 被 MCP+A2A 覆盖 |

### 4.2 可观测性 / 监控

| 平台 | 特性 | 定价 |
|------|------|------|
| **LangSmith** | 完整 trace + eval + hub | 付费 (LLM 调用计费) |
| **Langfuse** | OSS, OpenTelemetry, 自托管 | OSS 免费 |
| **Braintrust** | Eval-first, 数据集管理 | 付费 |
| **Helicone** | 缓存、成本优化、性能 | 付费 |
| **Phoenix** | Embedding drift + RAG eval | OSS |
| **Datadog LLM Obs** | 企业集成 | 企业版 |

### 4.3 评估 & 测试平台

- **Promptfoo** — CLI 优先，红队测试，CI 集成，"pytest for prompts"
- **DeepEval** — LLM 单元测试框架，丰富指标，数据集生成
- **Agenta** — Prompt 管理 + 人工评估
- **RAGAS** — RAG 流水线评估
- **Giskard** — 安全/鲁棒性扫描

### 4.4 Agent 测试基础设施难点

- **多步轨迹评估**: 路径正确性而非仅最终输出
- **非确定性**: 同一 prompt 多次输出可能不同
- **测试成本**: 每次测试调用 LLM API，费用高
- **CI/CD 集成**: Promptfoo CI 跑在 PR 上、GitHub Actions + DeepEval

---

## 五、OpenCode 实现原理分析

### 5.1 技术栈

- **语言**: TypeScript (Bun runtime)
- **核心框架**: [Effect-TS](https://effect.website/) — 纯函数式 TypeScript，代数效应、依赖注入、Schema、Stream
- **LLM SDK**: Vercel AI SDK (`@ai-sdk/*`)
- **状态管理**: Immer (不可变状态更新)
- **Schema 验证**: 自建 Zod-like schema 系统
- **包管理**: Bun monorepo

### 5.2 项目结构

```
packages/
├── core/          # Agent 核心 (@opencode-ai/core)
│   ├── src/
│   │   ├── agent.ts      — Agent 定义、管理、CRUD
│   │   ├── model.ts      — 模型定义、能力、成本
│   │   ├── provider.ts   — Provider 定义 (OpenAI, Anthropic, Google...)
│   │   ├── session.ts    — Session ID 生成
│   │   ├── plugin.ts     — 插件/Hook 系统
│   │   ├── permission.ts — 权限系统 (Allow/Deny/Ask)
│   │   ├── tool-output.ts— 工具输出定义
│   │   └── ...           — git, filesystem, process 等
├── console/       # CLI 终端
├── app/           # Web UI / 桌面应用
├── containers/    # Docker 容器定义
├── extensions/    # IDE 扩展
└── docs/          # 文档
```

### 5.3 核心架构模式

**依赖注入 (Effect Layer)**:
```typescript
class Service extends Context.Service<Service, Interface>()("@opencode/v2/Agent") {}
export const layer = Layer.effect(Service, Effect.gen(function* () {
  const plugin = yield* PluginV2.Service
  // ... 实现
  return Service.of(result)
}))
```

**插件/Hook 系统**:
```typescript
type HookSpec = {
  "catalog.transform": { input: Catalog.Context, output: {} }
  "agent.update": { input: {}, output: { agent: AgentV2.Info, cancel: boolean } }
  "aisdk.language": { input: { model, sdk, options }, output: { language? } }
  // ...
}
```
通过 `plugin.trigger()` 在关键生命周期点触发 hook，实现高度可扩展。

**Provider 模型**:
```typescript
export const Endpoint = Schema.Union([
  OpenAIResponses,      // type: "openai/responses" | "openai/completions"
  AnthropicMessages,    // type: "anthropic/messages"
  AISDK,                // type: "aisdk"
  UnknownEndpoint,      // type: "unknown"
])
```
支持 15+ provider，通过 `@ai-sdk/*` adapter 统一接口。

**权限系统**:
```typescript
export const Rule = Schema.Struct({
  permission: Schema.String,  // 工具名或通配符
  pattern: Schema.String,     // 路径模式
  action: Action,             // allow | deny | ask
})
```
通配符匹配，合并多层 ruleset，实现细粒度访问控制。

### 5.4 Agent 循环 (推测)

基于 Effect-TS 的纯函数式循环:
1. 构建 Session (包含 Prompt + 上下文)
2. 通过 Provider 调用模型 (OpenAI/Anthropic 格式)
3. 解析 tool_calls → 通过权限检查 → 执行工具
4. 工具结果返回 → 继续循环
5. Stream 处理 (SSE/WebSocket)
6. 插件 hook 在每个环节可介入

---

## 六、Hermes Agent 实现原理分析

### 6.1 技术栈

- **语言**: Python
- **LLM 调用**: 自建 OpenAI 兼容客户端 (支持 streaming)
- **Schema**: JSON Schema (手动定义工具参数)
- **状态管理**: SQLite (`hermes_state.py`)
- **依赖注入**: 全局单例模式
- **CLI**: `prompt_toolkit` (交互式)

### 6.2 项目结构

```
hermes-agent/
├── run_agent.py           # AIAgent 核心类 ~4000行
├── agent/
│   ├── conversation_loop.py  # run_conversation 主循环
│   ├── prompt_builder.py     # 系统提示词构建
│   ├── tool_executor.py      # 工具调度执行
│   ├── memory_manager.py     # 跨会话记忆
│   ├── context_compressor.py # 上下文压缩
│   └── ...
├── tools/                 # 每个文件一个工具
│   ├── registry.py        # 中央工具注册表
│   ├── terminal_tool.py
│   ├── file_tools.py
│   ├── web_tools.py
│   └── ...
├── hermes_cli/            # CLI 子命令
│   ├── commands.py        # Slash 命令注册
│   └── main.py            # 入口 + argparse
├── gateway/               # 消息网关
│   └── platforms/         # Telegram/Discord/Slack...
├── cron/                  # 定时任务调度器
├── toolsets.py            # 工具集定义
└── tests/                 # ~3000 测试
```

### 6.3 核心架构模式

**Agent 循环 (run_conversation)**:
```python
def run_conversation(agent, system_message, conversation_history):
    # 1. 构建/恢复系统提示词 (SQLite 缓存)
    # 2. 循环 while iterations < max:
    #    a. 调用 LLM (OpenAI 格式 messages + tool schemas)
    #    b. 如果有 tool_calls → dispatch 每个
    #    c. 如果有文本响应 → return
    # 3. 接近 token 限制时触发上下文压缩
```

**工具系统**:
```python
tools/registry.py:
  registry.register(
      name="example_tool",
      toolset="example",
      schema={"name": "...", "parameters": {...}},
      handler=lambda args, **kw: ...,
      check_fn=check_requirements,  # 条件启用
      requires_env=["API_KEY"],
  )
```
自动发现: 任何 `tools/*.py` 文件有顶层 `registry.register()` 自动导入。

**工具集系统**:
```python
_HERMES_CORE_TOOLS = [
    "web_search", "terminal", "read_file", "write_file",
    "vision_analyze", "delegate_task", ...
]
TOOLSETS = {
    "web": {"tools": ["web_search", "web_extract"]},
    "browser": {"tools": ["browser_navigate", ...]},
    ...
}
```
每个平台 (CLI/Telegram/Discord) 可选择不同工具集组合。

**记忆系统**:
- `memory_manager.py` — 构建记忆上下文块
- 可插拔后端 (内置/Honcho/Mem0)
- `session_search.py` — 跨会话搜索

**上下文压缩**:
- `conversation_compression.py` — 接近 token 限制时自动压缩
- `context_compressor.py` — 压缩引擎
- `agent/context_engine.py` — 上下文引擎

### 6.4 插件/MCP 支持

- `tools/mcp_tool.py` — MCP 客户端，连接外部 MCP 服务器
- `plugins/` — 插件目录
- `agent/plugin_llm.py` — LLM 插件支持

---

## 七、OpenCode vs Hermes 架构对比

| 维度 | OpenCode | Hermes Agent |
|------|----------|-------------|
| **语言** | TypeScript (Bun) | Python |
| **核心范式** | 纯函数式 (Effect-TS) | 命令式 + 全局状态 |
| **依赖注入** | Effect Layer (编译期类型安全) | 无 (全局单例) |
| **Schema 验证** | 自建 Schema (类型安全) | JSON Schema (运行期) |
| **LLM SDK** | Vercel AI SDK (`@ai-sdk/*`) | 自建 OpenAI 兼容客户端 |
| **工具注册** | Effect 服务层 | 注册表模式 |
| **插件系统** | Hook-based (类型安全) | Hook + MCP |
| **多平台** | CLI + 桌面 + IDE 扩展 | CLI + Gateway (10+ 平台) |
| **记忆** | 有限 (靠 Effect 状态) | SQLite + 可插拔后端 |
| **可扩展性** | Effect Layer + Plugin Hook | 注册表 + MCP + 插件 |
| **学习曲线** | 陡 (Effect-TS) | 平 (标准 Python) |
| **社区** | ~166k stars | ~30k stars |

---

## 八、简易版 Agent 实现方案

### 8.1 核心架构 (最小可行)

```
┌─────────────────────────────────────────────┐
│                 Agent Loop                    │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐ │
│  │ LLM Call  │──>│ Tool     │──>│ Tool     │ │
│  │ (stream)  │   │ Dispatch │   │ Execute  │ │
│  └──────────┘   └──────────┘   └──────────┘ │
│       ↑                                      │
│       └──── context + memory ──────────────── │
└─────────────────────────────────────────────┘
```

### 8.2 建议技术栈 (Python)

```python
# 核心依赖
openai          # LLM 调用
pydantic        # Schema 验证 (替代 JSON Schema)
sqlite3         # 状态/会话/记忆存储
httpx           # HTTP 工具
asyncio         # 异步 (多 agent 并行)
```

### 8.3 核心组件实现

**1. LLM Client 封装**
```python
from openai import OpenAI
from typing import Callable, Dict, Any

class LLMClient:
    def __init__(self, api_key: str, base_url: str, model: str):
        self.client = OpenAI(api_key=api_key, base_url=base_url)
        self.model = model

    def chat(self, messages, tools=None, stream=True):
        return self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            tools=tools,
            stream=stream,
        )
```

**2. Tool System (注册表模式)**
```python
from pydantic import BaseModel, Field
from typing import Dict, Callable

class Tool(BaseModel):
    name: str
    description: str
    parameters: Dict  # JSON Schema
    handler: Callable

class ToolRegistry:
    def __init__(self):
        self._tools: Dict[str, Tool] = {}

    def register(self, tool: Tool):
        self._tools[tool.name] = tool

    def get_schemas(self) -> list:
        return [{
            "type": "function",
            "function": {
                "name": t.name,
                "description": t.description,
                "parameters": t.parameters,
            }
        } for t in self._tools.values()]

    def execute(self, name: str, args: dict) -> str:
        tool = self._tools.get(name)
        if not tool:
            return f"Error: tool '{name}' not found"
        return tool.handler(**args)
```

**3. Agent Loop**
```python
class Agent:
    def __init__(self, llm: LLMClient, registry: ToolRegistry):
        self.llm = llm
        self.registry = registry
        self.messages = []

    async def run(self, user_input: str):
        self.messages.append({"role": "user", "content": user_input})

        for _ in range(MAX_ITERATIONS):
            response = self.llm.chat(
                messages=self.messages,
                tools=self.registry.get_schemas(),
            )

            msg = response.choices[0].message

            if not msg.tool_calls:
                self.messages.append({"role": "assistant", "content": msg.content})
                return msg.content

            self.messages.append(msg)
            for tc in msg.tool_calls:
                result = self.registry.execute(tc.function.name, 
                                                json.loads(tc.function.arguments))
                self.messages.append({
                    "role": "tool",
                    "tool_call_id": tc.id,
                    "content": result,
                })

        return "Max iterations reached"
```

**4. Memory (SQLite)**
```python
import sqlite3, json

class MemoryStore:
    def __init__(self, db_path="agent_memory.db"):
        self.conn = sqlite3.connect(db_path)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS memory (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

    def save(self, key: str, value: dict):
        self.conn.execute(
            "INSERT OR REPLACE INTO memory (key, value) VALUES (?, ?)",
            (key, json.dumps(value))
        )
        self.conn.commit()

    def load(self, key: str) -> dict | None:
        row = self.conn.execute(
            "SELECT value FROM memory WHERE key = ?", (key,)
        ).fetchone()
        return json.loads(row[0]) if row else None
```

### 8.4 简易 Multi-Agent 实现

```python
# 角色定义
class RoleAgent(Agent):
    def __init__(self, name: str, role_prompt: str, llm, registry):
        super().__init__(llm, registry)
        self.name = name
        self.messages = [{"role": "system", "content": role_prompt}]

# 简单协调器 (Sequential Pattern)
class SequentialCoordinator:
    def __init__(self):
        self.agents = []

    def add(self, agent: RoleAgent):
        self.agents.append(agent)

    async def run(self, task: str):
        result = task
        for agent in self.agents:
            agent.messages.append({
                "role": "user", 
                "content": f"Previous output: {result}\nYour task: process this"
            })
            result = await agent.run(result)
        return result

# 分层协调器 (Manager pattern)
class ManagerCoordinator:
    def __init__(self, manager: Agent, workers: Dict[str, Agent]):
        self.manager = manager
        self.workers = workers

    async def run(self, task: str):
        plan = await self.manager.run(f"Plan: {task}")
        # Parse plan, assign subtasks to workers
        results = {}
        for worker_name, subtask in self._parse_plan(plan):
            worker = self.workers[worker_name]
            results[worker_name] = await worker.run(subtask)
        # Synthesize results
        final = await self.manager.run(
            f"Synthesize: {json.dumps(results)}"
        )
        return final
```

### 8.5 简易 Harness

```python
class AgentHarness:
    def __init__(self, agent: Agent):
        self.agent = agent

    async def evaluate(self, test_cases: list[dict]) -> dict:
        results = []
        for case in test_cases:
            output = await self.agent.run(case["input"])
            passed = self._check(case["expected"], output)
            results.append({
                "input": case["input"],
                "expected": case["expected"],
                "output": output,
                "passed": passed,
            })
        return {
            "total": len(results),
            "passed": sum(1 for r in results if r["passed"]),
            "results": results,
        }

    def _check(self, expected: str | Callable, output: str) -> bool:
        if callable(expected):
            return expected(output)
        return expected == output
```

### 8.6 整体架构图

```
┌─────────────────────────────────────────────────────┐
│                     Agent System                      │
│                                                       │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────┐  │
│  │  LLM Client  │   │ Tool Registry│   │  Memory   │  │
│  │ (OpenAI SDK) │   │ (注册表模式)  │   │ (SQLite)  │  │
│  └──────┬──────┘   └──────┬───────┘   └─────┬────┘  │
│         │                 │                  │        │
│         └─────────────────┼──────────────────┘        │
│                           │                           │
│                    ┌──────▼───────┐                   │
│                    │  Agent Loop   │                   │
│                    │ (msg→tools→   │                   │
│                    │  msg→...)     │                   │
│                    └──────┬───────┘                   │
│                           │                           │
│              ┌────────────┼────────────┐              │
│              │            │            │              │
│         ┌────▼───┐  ┌────▼───┐  ┌────▼───┐         │
│         │CLI App │  │Gateway │  │  Eval  │         │
│         │(REPL)  │  │(API)   │  │Harness │         │
│         └────────┘  └────────┘  └────────┘         │
└─────────────────────────────────────────────────────┘
```

### 8.7 从零实现路线图

| 阶段 | 内容 | 预估 |
|------|------|------|
| **Phase 1** | LLM Client + Tool Registry + Agent Loop | 1-2 天 |
| **Phase 2** | CLI REPL + Session (SQLite) + 基础工具集 | 2-3 天 |
| **Phase 3** | Multi-Agent 协调器 + Memory 系统 | 3-5 天 |
| **Phase 4** | Agent Harness + Eval 框架 | 2-3 天 |
| **Phase 5** | Gateway (API Server) + 插件系统 | 5-7 天 |

**关键设计原则**:
1. **保持简单** — 先做单 agent 循环，再扩展到 multi-agent
2. **工具优先** — 工具注册表是核心，设计好它的 schema
3. **可观测性** — 从一开始就加 logging/tracing
4. **配置驱动** — Provider 切换通过 config，不改代码
5. **渐进式** — CLI first，再 gateway，再 IDE 集成

---

## 九、总结与建议

### 9.1 趋势判断

1. **Agent Harness 将标准化** — Inspect (UK AISI) 可能成为 Agent 评估的 "pytest"
2. **Proactive AI 走向领域特化** — 全通用自主 agent 仍有 gap，领域内 proactive 已可行
3. **Multi-Agent 分化** — LangGraph(图) vs CrewAI(角色) vs AutoGen(对话)，各有所长
4. **Agent Infra 三层化** — MCP(工具) + A2A(通信) + LangSmith(可观测)
5. **MCP 协议成为事实标准** — 所有 agent 框架都在支持 MCP

### 9.2 建议关注的方向

- **MCP 集成** — 让你的 agent 能消费 MCP 工具市场
- **Agent 评估体系** — 建立 CI 流程中的 agent eval pipeline
- **记忆系统** — 好的记忆 = 好的 proactive agent 基础
- **可观测性** — 没有 trace 就没有 debug
- **渐进式 multi-agent** — 先单 agent + 子任务委托，再扩展
