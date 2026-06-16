---
title: "MemPalace：给 AI 一个真正的记忆，不要 API Key，不要云端"
date: 2026-06-16
draft: false
tags:
  - AI
  - 记忆系统
  - 开源
  - 本地部署
---

你试过和 AI 聊了一下午，切个会话它就什么都不记得了——连你刚说的项目背景都要重新交代一遍。

MemPalace 就是来解决这个问题的。一个**本地优先的开源 AI 记忆系统**，55k stars，MIT 协议。核心路径不需要任何 API Key，完全离线运行。

## 它做了什么不同的事？

大多数"记忆系统"做的是**摘要**——把对话浓缩成几句 embedding 向量，信息损耗严重。MemPalace 选择**逐字存储**原文，用一套叫 AAAK 的紧凑符号语言做索引层，让 LLM 能快速定位数千个会话抽屉。

存储结构是四层嵌套：**宫殿 → 侧厅(Wing) → 房间(Room) → 抽屉(Drawer)**。每个项目/Agent 有独立的 Wing，每次搜索可以限定范围，不用在平铺语料库里大海捞针。

## 数据说话

| 模式 | LongMemEval R@5 | 需 LLM？ |
|------|:-:|:-:|
| Raw 纯语义搜索 | **96.6%** | ❌ |
| Hybrid v4 | **98.4%** | ❌ |
| Hybrid + LLM rerank | ≥99% | ✅ |

96.6% 裸召回不需要任何 AI 模型参与——纯语义搜索。Benchmark 全部可复现，代码和数据集都在仓库里。

## 生态集成

- **29 个 MCP 工具**——任何 MCP 客户端都能接入（Claude Code、Zed、VS Code 等）
- **Claude Code hooks**——自动保存，解决 30 天会话过期问题
- **Codex 插件 + Claude 插件**——两大 CLI Agent 开箱即用
- **4 种存储后端**——ChromaDB（默认）、Qdrant、pgvector、SQLite 精确校验
- **知识图谱**——时序实体关系图，有效窗口管理
- **Docker**——含 GPU 加速（CUDA/DirectML/CoreML）

## 安装

```bash
uv tool install mempalace
mempalace init ~/projects/myapp
```

三行命令，你的 AI 就有了一个本地记忆宫殿。

---

*团队做 Agent 记忆方案的，值得看看它的评测方法论和 MCP 接口设计。仓库：github.com/MemPalace/mempalace*
