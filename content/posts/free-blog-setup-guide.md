---
title: "免费搭建个人技术博客：Hugo + GitHub + Vercel 完全指南"
date: 2026-06-16
draft: false
tags:
  - 教程
  - Hugo
  - Vercel
  - GitHub
  - 博客
  - 免费
---

## 前言

想拥有一个个人技术博客，但不想花钱买服务器、不想折腾运维、不想被平台绑架？

本文介绍一条**完全免费**的搭建路线：Hugo + GitHub + Vercel。全程零成本，国内可访问，开发者友好。

> 这篇教程本身就是用这个方案发布的。

---

## 方案概览

| 组件 | 作用 | 成本 |
|------|------|------|
| **Hugo** | 静态站点生成器 | 免费，开源 |
| **GitHub** | 源码托管 | 免费 |
| **Vercel** | 自动构建 + 全球 CDN 部署 | 免费（100GB 带宽/月） |
| **PaperMod** | Hugo 主题 | 免费，开源 |

**工作流：** 本地写 Markdown → `git push` → Vercel 自动构建发布

---

## 第一步：安装 Hugo

Hugo 是用 Go 写的单二进制文件。下载最新 release：

```bash
# 下载 Hugo Extended 版（支持 SCSS）
curl -sL "https://github.com/gohugoio/hugo/releases/download/v0.147.0/hugo_extended_0.147.0_linux-amd64.tar.gz" -o /tmp/hugo.tar.gz
tar -xzf /tmp/hugo.tar.gz -C /tmp hugo
sudo mv /tmp/hugo /usr/local/bin/hugo

# 验证
hugo version
```

> **注意：** PaperMod 主题要求 Hugo 0.146+，不要用系统自带的旧版。

## 第二步：初始化站点

```bash
hugo new site tech-blog
cd tech-blog
git init
```

## 第三步：安装主题（PaperMod）

这里有个**坑**：不建议用 git submodule，因为 Vercel CLI 部署时没有 git 上下文，拉不到子模块。

正确做法：直接把主题文件克隆到 `themes/` 目录并提交到仓库。

```bash
git clone --depth 1 https://github.com/adityatelange/hugo-PaperMod themes/PaperMod
rm -rf themes/PaperMod/.git   # 去掉子模块信息
```

## 第四步：配置文件

新建 `hugo.yaml`（用 YAML 格式，比 TOML 更简洁）：

```yaml
baseURL: "/"
languageCode: "zh-cn"
title: "我的技术博客"
theme: "PaperMod"
pagination:
  pagerSize: 10

params:
  description: "个人技术博客"
  author: "Your Name"
  homeInfoParams:
    Title: "你好 👋"
    Content: "欢迎来到我的技术博客。"
  socialIcons:
    - name: "github"
      url: "https://github.com/your-username"
    - name: "rss"
      url: "index.xml"
  ShowToc: true
  ShowReadingTime: true
  ShowCodeCopyButtons: true

menu:
  main:
    - identifier: "posts"
      name: "文章"
      url: "/posts/"
      weight: 10
    - identifier: "tags"
      name: "标签"
      url: "/tags/"
      weight: 20
    - identifier: "search"
      name: "搜索"
      url: "/search/"
      weight: 25
    - identifier: "about"
      name: "关于"
      url: "/about/"
      weight: 30

outputs:
  home: ["HTML", "RSS", "JSON"]
```

### 添加搜索页面

PaperMod 内置搜索功能，需要创建一个页面：

```bash
cat > content/search.md << 'EOF'
---
title: "搜索"
layout: "search"
placeholder: "输入关键词搜索..."
---
EOF
```

### 自定义样式（可选）

在 `assets/css/extended/custom.css` 中写自定义样式，PaperMod 会自动加载：

```css
/* 站点标题渐变 */
.logo a {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* 文章卡片悬浮效果 */
.post-entry {
  transition: all 0.3s ease;
}
.post-entry:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
}
```

## 第五步：写第一篇文章

```bash
hugo new content posts/my-first-post.md
```

用 Markdown 写内容：

```markdown
---
title: "我的第一篇博客"
date: 2025-06-16
draft: false
tags:
  - hello
---

## 你好，世界！

这是我的第一篇博客。用 Markdown 写内容，支持代码高亮、表格、图片等。
```

## 第六步：验证本地构建

```bash
hugo --gc
```

能正常生成 `public/` 目录就算成功。注意**不要加 `--minify` 参数**，PaperMod 和 Hugo 的 minifier 有兼容问题，构建会失败。

## 第七步：推送到 GitHub

```bash
git add -A
git commit -m "init: Hugo blog"
git remote add origin https://github.com/your-username/tech-blog.git
git push -u origin main
```

## 第八步：部署到 Vercel

### 创建 vercel.json

```json
{
  "framework": "hugo",
  "installCommand": "curl -sL https://github.com/gohugoio/hugo/releases/download/v0.147.0/hugo_extended_0.147.0_linux-amd64.tar.gz -o /tmp/hugo.tar.gz && tar -xzf /tmp/hugo.tar.gz -C /tmp hugo && mv /tmp/hugo /usr/local/bin/hugo && chmod +x /usr/local/bin/hugo",
  "buildCommand": "hugo --gc"
}
```

> `installCommand` 确保 Vercel 使用正确的 Hugo 版本（Vercel 默认的 Hugo 0.58 太老，不支持 PaperMod）。

### 方式 A：Vercel CLI（推荐）

```bash
npm i -g vercel
vercel deploy --prod
```

首次运行会引导登录，之后每次 `git push` 后执行 `vercel deploy --prod` 即可。

### 方式 B：Vercel Web 控制台

打开 https://vercel.com/import → 导入 GitHub 仓库 → Framework 选 Hugo → Deploy。

## 以后写文章

```bash
hugo new content posts/新文章.md
# 用编辑器写 Markdown
git add -A && git commit -m "新文章"
git push            # Vercel 自动部署
```

或者直接用 `vercel deploy --prod`（不经过 GitHub）。

---

## 踩坑记录

### 1. `--minify` 导致空页面

PaperMod 和 Hugo 的 HTML minifier 不兼容，构建时会在渲染阶段报 JSON 解析错误，`public/` 目录里只有 XML 没有 HTML。**始终去掉 `--minify`。**

### 2. Git submodule 导致 Vercel 部署失败

如果用 `git submodule` 添加主题，Vercel CLI 部署时没有 git 上下文，拉不到主题文件。**直接把主题文件放到仓库里。**

### 3. Vercel 缓存导致更新不生效

Vercel 会缓存构建输出，如果缓存里有旧版本的文件，新部署会直接复用缓存。解决方法：
- 用 `vercel deploy --prod` 创建**新项目**（不同项目名）
- 或在 Vercel 仪表盘手动清除构建缓存

### 4. Hugo 版本太旧

Vercel 默认装的 Hugo 0.58.2（2019年发布），新主题要求 0.146+。在 `installCommand` 中手动下载指定版本。

---

## 效果展示

最终效果：
- 博客主页显示文章列表
- 自动生成 RSS、搜索、标签
- 暗色/亮色主题切换
- 代码高亮、文章目录
- GitHub 社交链接
- 国内读者可正常访问

---

## 总结

Hugo + GitHub + Vercel 是目前最成熟的免费博客方案。全文零成本，Markdown 写内容，`git push` 即发布。适合所有开发者。

**关键记住三点：**
1. 主题直接放仓库，不用子模块
2. 去掉 `--minify`
3. Vercel 要指定 Hugo 版本
