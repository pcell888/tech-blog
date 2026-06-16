#!/usr/bin/env bash
set -e

BLOG_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=== 技术博客部署脚本 ==="
echo ""

# 检查是否已登录 GitHub
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  echo "[1/3] 创建 GitHub 仓库..."
  gh repo create tech-blog --public --source="$BLOG_DIR" --remote=origin --push
  REPO_URL="https://github.com/$(gh repo view --json nameWithOwner -q '.nameWithOwner')"
  echo "  仓库已创建: $REPO_URL"
else
  echo "[1/3] GitHub 仓库创建（手动步骤）"
  echo "  请手动操作："
  echo "  1. 打开 https://github.com/new"
  echo "  2. 仓库名: tech-blog"
  echo "  3. 设为 Public，不要勾选任何初始化选项"
  echo "  4. 点击 Create repository"
  echo "  5. 然后回到终端执行："
  echo ""
  echo "     cd $BLOG_DIR"
  echo "     git remote add origin https://github.com/<你的用户名>/tech-blog.git"
  echo "     git push -u origin main"
  echo ""
  read -p "  按回车继续部署到 Vercel..."
fi

echo ""
echo "[2/3] 检测 Vercel CLI..."

if command -v vercel &>/dev/null; then
  echo "  Vercel CLI 已安装，开始部署..."
  cd "$BLOG_DIR"
  vercel --prod
else
  echo "  推荐使用 Vercel CLI 部署，运行："
  echo ""
  echo "     npm i -g vercel"
  echo "     cd $BLOG_DIR"
  echo "     vercel --prod"
  echo ""
  echo "  或者直接在浏览器操作："
  echo "  1. 打开 https://vercel.com/import"
  echo "  2. 导入 GitHub 仓库 tech-blog"
  echo "  3. Vercel 会自动识别 Hugo 配置，无需额外设置"
  echo "  4. 部署完成后访问 https://tech-blog.vercel.app"
fi

echo ""
echo "=== 部署完成！ ==="
echo ""
echo "后续写文章："
echo "  在 content/posts/ 下创建新的 Markdown 文件，例如："
echo "    hugo new content posts/my-new-post.md"
echo "  用 Markdown 格式写内容，git push 即自动发布。"
