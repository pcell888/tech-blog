---
title: "whichllm：你的硬件该跑哪个本地大模型？一条命令出答案"
date: 2026-06-16
draft: false
tags:
  - AI
  - LLM
  - 工具推荐
  - 本地模型
---

> 2026-06-09 · #AI #LLM #工具推荐

---

装了个本地 LLM，跑了才发现卡成 PPT；想换显卡，又不确定买了能提升多少——这两种情况遇过吧？

**whichllm** 就是解决这个问题的。一条命令，自动检测你硬件，告诉你哪个模型最好。

## 一条命令

```bash
uvx whichllm@latest          # 自动检测+推荐
uvx whichllm@latest --gpu "RTX 4090"   # 买显卡前模拟
```

`uvx` 零安装直接跑。想装本地就 `uv tool install whichllm`。

输出示例：

```
$ whichllm --gpu "RTX 4090"

#1  Qwen/Qwen3.6-27B     27.8B  Q5_K_M   score 92.8    27 t/s
#2  Qwen/Qwen3-32B       32.0B  Q4_K_M   score 83.0    31 t/s
#3  Qwen/Qwen3-30B-A3B   30.0B  Q5_K_M   score 82.7   102 t/s
```

第一名不是参数量最大的，而是**实测评分最高的**——这恰恰是它和其他"能塞进显存就行"的工具最大的区别。

## 它和"按显存筛选"有什么不同？

市面上找本地模型的传统路径：

1. 去 HuggingFace 搜，看参数量猜性能
2. 用 `ollama list` 看跑过的，但不知道外面有更好的
3. 看排行榜，但不知道自己的显卡跑不跑得动

whichllm 把 **"哪个模型实测最好 + 我的显卡能不能跑"** 两个问题一次解决。

背后的逻辑：

| 因素 | 它是怎么处理的 |
|---|---|
| 评测数据 | 融合 LiveBench / Arena ELO / Aider 等 6 个来源，不是只看参数量 |
| 时效 | 2024 年老模型不会靠旧分数压过新一代 |
| 证据可信度 | 直接评测 > 家族继承 > 上传者自报，跨家族蹭分直接拒绝 |
| VRAM 估算 | weights + KV Cache + activation + overhead 逐项算 |
| MoE 模型 | 质量用总参，速度用活跃参，分开算 |

## 更多玩法

```bash
whichllm plan "llama 3 70b"               # 跑这个模型需要什么显卡？
whichllm upgrade "RTX 4090" "RTX 5090"     # 对比升级收益
whichllm run "qwen 2.5 1.5b gguf"         # 一键下载+开聊
whichllm snippet "qwen 7b"                # 输出可直接粘贴的 Python
whichllm --profile coding --top 1 --json   # 找最好的编程模型，JSON 输出
```

## 一句话总结

不是所有 7B 都一样，也不是显存装得下就合适。whichllm 帮你跳过"这模型到底行不行"的试错——**买卡之前模拟，装模型之前查榜，一条命令全搞定**。

> 开源项目（MIT），Python 实现，GitHub 3.5k stars。  
> 仓库：https://github.com/Andyyyy64/whichllm
