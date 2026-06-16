---
title: "MDX：当 Markdown 遇上 JSX，内容创作的组件时代"
date: 2026-06-16
draft: false
tags:
  - MDX
  - Markdown
  - JSX
  - 前端
---

## 一、什么是 MDX？

MDX 是一种将 Markdown 和 JSX 融合在一起的文档格式。它让你可以在 Markdown 内容中直接导入和使用 React/Vue 等组件，把静态文档变成可交互的内容体验。

简单来说，MDX = Markdown + JSX。

一个典型的 MDX 文件长这样：

```mdx
import {Chart} from './snowfall.js'
export const year = 2023

# 去年降雪量

在 {year} 年，降雪量高于平均水平。
随后温暖的春天导致附近多条河流泛滥。

<Chart color="#fcb32c" year={year} />
```

这段代码在编译后会渲染出标题、段落文本，以及一个可交互的图表组件——纯 Markdown 做不到的事，MDX 轻松搞定。

MDX 由社区维护，目前最新稳定版是 **MDX 3**（2024 年发布），基于 unified/remark/rehype 生态构建，编译时无运行时开销。

---

## 二、核心特性

### 1. 在 Markdown 中嵌入 JSX

这是 MDX 最核心的能力。你可以在 Markdown 段落中直接插入 `<Alert />`、`<Chart />`、`<VideoPlayer />` 等任意组件，让文档拥有交互能力。

### 2. 导入组件和模块

```mdx
import {Box} from '@primer/react'
import {MyMap} from '../components/map.js'
import {notes} from './notes.js'
```

支持 ESM 导入语法，可以引入 npm 包、本地组件、甚至其他 MDX 文件。

### 3. 导出变量

可以在 MDX 中定义 JS 变量并在文档中使用：

```mdx
export const title = 'MDX 入门'
export const authors = ['张三', '李四']

# {title}

作者：{authors.join('、')}
```

### 4. 自定义 Markdown 元素映射

你可以决定每个 Markdown 语法对应的渲染组件：

```jsx
// 将 # 标题渲染为自定义组件
const components = {
  h1: MyHeading,
  h2: (props) => <h2 style={{color: 'blue'}} {...props} />,
  code: CodeBlock,
  img: ZoomableImage,
}
```

这让品牌化文档系统变得极为方便。

### 5. 编译时构建，零运行时

MDX 在构建阶段将文档编译为 JavaScript 模块，生产环境没有额外运行时开销。兼容所有主流打包工具。

---

## 三、工作原理

MDX 的编译流程分为三个阶段：

```
.md 文件 → [解析] → AST → [转换] → JSX AST → [编译] → .js 模块
```

底层依赖 **unified** 生态系统：
- **remark**：解析 Markdown 为 mdast（Markdown AST）
- **remark-mdx**：扩展 mdast 支持 JSX 节点
- **rehype**：将 mdast 转换为 hast（HTML AST）
- **@mdx-js/mdx**：将 hast 编译为 JavaScript 模块

最终产出的 JS 模块可以直接在 React、Preact、Vue、Solid 等框架中使用。

---

## 四、使用场景

### 📝 场景 1：技术博客 & 文档站点

这是 MDX 最成熟的场景。相比普通 Markdown，MDX 让技术博客可以嵌入：

- **代码沙盒**：嵌入 CodeSandbox 或 CodePen 的交互式 demo
- **可运行代码**：搭配 CodeSurfer 或 Sandpack 组件，读者直接在页面上编辑运行代码
- **自定义提示框**：用 `<Note>`、`<Warning>`、`<Tip>` 组件替代纯文本的 blockquote
- **图表 & 数据可视化**：嵌入 D3、Chart.js 等可视化组件

典型项目：**Next.js 官方文档**、**Docusaurus 站点**、**Gatsby 博客** 都在大量使用 MDX。

### 🏗 场景 2：设计系统 & 组件文档

设计系统的组件文档需要同时展示代码和渲染结果。MDX 是这一需求的天选格式：

```mdx
import {Button} from './Button.js'

## Button 组件

### 基础用法

<Button variant="primary">提交</Button>
<Button variant="secondary">取消</Button>

### 禁用状态

<Button disabled>不可点击</Button>

### 使用方式

```jsx
<Button variant="primary">提交</Button>
```
```

每个组件的文档页面可以同时包含说明文字、代码示例和实时渲染效果。Storybook 的文档模式、Docusaurus 的组件文档都基于此。

### 🎓 场景 3：交互式教材 & 在线课程

教育类内容天然需要交互。MDX 让教材编写者可以：

- 嵌入 **数学公式**（LaTeX/MathML）
- 插入 **交互式测验** 组件
- 集成 **Jupyter Notebook** 的输出
- 添加 **可折叠代码块**、**步骤引导**、**进度追踪** 组件

```mdx
import {Quiz, StepByStep, Formula} from '../components'

## 牛顿第二定律

<Formula math="F = ma" />

### 理解概念

<Quiz
  question="力、质量和加速度之间的关系是？"
  options={['F = ma', 'F = m/a', 'F = a/m']}
  correct={0}
/>
```

### 📊 场景 4：数据报告 & 仪表盘

数据团队可以写 Markdown 风格的报告，同时嵌入实时数据可视化：

```mdx
import {SalesChart, KPICard} from '../components/dashboard'
import {salesData} from '../data/q4'

# Q4 销售报告

## 整体概览

<KPICard label="总收入" value={salesData.revenue} trend="+12.5%" />
<KPICard label="活跃用户" value={salesData.activeUsers} trend="+8.3%" />

## 趋势分析

<SalesChart data={salesData.monthly} />
```

相比纯 BI 工具，MDX 报告兼具**叙事深度**和**数据交互**。

### 🌐 场景 5：企业知识库 & 内部 Wiki

使用 Docusaurus 或 Next.js 搭建的 Wiki 支持 MDX 后，团队成员可以在文档中：

- 嵌入 **Jira 看板** 或 **Trello 卡片**
- 插入 **组织架构图** 组件
- 嵌入 **Google Sheets / Airtable** 视图
- 添加 **审批流程 / 状态徽标** 组件

### 🧩 场景 6：嵌入外部内容

MDX 配合 `mdx-embed` 等库可以轻松嵌入：

- **Twitter/X 推文**
- **YouTube / Bilibili 视频**
- **GitHub Gist**
- **CodePen / JSFiddle**
- **Figma 设计稿预览**

```mdx
import { Tweet, YouTube, GitHubGist } from 'mdx-embed'

<Tweet url="https://twitter.com/username/status/123456" />
<YouTube youTubeId="dQw4w9WgXcQ" />
```

---

## 五、框架集成生态

MDX 几乎支持所有主流前端框架和构建工具：

| 框架/工具 | 集成方式 |
|-----------|----------|
| **Next.js** | `@next/mdx` 官方支持，App Router 已原生支持 |
| **Docusaurus** | Meta 官方的文档框架，内置 MDX 支持 |
| **Gatsby** | `gatsby-plugin-mdx` 插件 |
| **Vite** | `@mdx-js/rollup` 或 `vite-plugin-mdx` |
| **Astro** | 原生支持 `.mdx` 文件 |
| **Remix** | `@mdx-js/rollup` 或 `mdx-bundler` |
| **Webpack** | `@mdx-js/loader` |
| **esbuild** | `@mdx-js/esbuild` |
| **Storybook** | MDX 作为 CSF 格式写组件 stories |

---

## 六、MDX 3 新特性（2024）

MDX 3 是一个小型大版本，主要变化：

- **停止支持 Node < 16**，拥抱现代 JavaScript
- **ES2024 支持**：在 MDX 中使用最新的 JS 语法
- **`await` 支持**：如果框架支持，可以在 MDX 顶层使用 `await`（对数据加载型内容非常有用）
- **移除若干废弃选项**，API 更精简

---

## 七、快速上手

### 安装

```bash
npm install @mdx-js/loader @mdx-js/react
```

### 在 Next.js 中使用

```js
// next.config.js
import createMDX from '@next/mdx'

const withMDX = createMDX()
export default withMDX({ pageExtensions: ['js', 'jsx', 'mdx'] })
```

### 在 Vite 中使用

```js
// vite.config.js
import mdx from '@mdx-js/rollup'
import {defineConfig} from 'vite'

export default defineConfig({
  plugins: [mdx()]
})
```

然后创建一个 `.mdx` 文件，导入组件即可开始使用。

---

## 八、总结

MDX 解决了内容开发中的一个根本矛盾：**Markdown 擅长写作但缺少交互能力，JSX 擅长交互但写作体验笨重**。MDX 让两者各取所长——用 Markdown 的简洁写内容，用 JSX 的灵活做交互。

无论你是写技术博客、搭文档站点、建设计系统、编在线教材还是做数据报告，MDX 都能让你的内容从"可读"进化到"可交互"。在组件化开发成为主流的今天，MDX 正是"内容组件化"的最佳实践。

> 项目官网：https://mdxjs.com
> GitHub：https://github.com/mdx-js/mdx
> 开源协议：MIT License

---

*本文发布于 2026 年 5 月，基于 MDX 3 版本撰写。*
