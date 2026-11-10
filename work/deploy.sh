#!/bin/bash
# 一键发布：构建 → 推送 GitHub → 更新云服务器 → 线上验证
# 用法：项目有修改后在项目根目录运行  bash work/deploy.sh "提交说明"
set -e
cd "$(dirname "$0")/.."

MSG="${1:-update $(date +%Y%m%d-%H%M)}"
SERVER="root@60.205.204.162"
APP_DIR="/srv/apps/grad-timetable/app"
FILE="浙工商研究生课表浏览器2026秋.html"

echo "[1/4] 构建成品 HTML"
node work/build.js

echo "[2/4] 提交并推送 GitHub（1739467001-svg/zjgsu-grad-timetable）"
git add -A
git commit -m "$MSG" || echo "（无改动，跳过提交）"
git push

echo "[3/4] 上传到云服务器 $SERVER:$APP_DIR/（先自动备份线上版）"
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10"
if ! ssh $SSH_OPTS "$SERVER" true 2>/dev/null; then
  echo "✗ 服务器 SSH 连不上（本机网络或代理故障）。GitHub 已推送，服务器未更新——网络恢复后重跑本脚本即可。"; exit 3
fi
ssh $SSH_OPTS "$SERVER" "cp $APP_DIR/index.html $APP_DIR/index.html.bak-\$(date +%Y%m%d-%H%M) 2>/dev/null || true"
scp $SSH_OPTS "$FILE" "$SERVER:$APP_DIR/index.html"

echo "[4/4] 线上验证"
LOCAL_MD5=$(md5 -q "$FILE")
REMOTE_MD5=$(ssh $SSH_OPTS "$SERVER" "md5sum $APP_DIR/index.html" | cut -d' ' -f1)
if [ "$LOCAL_MD5" = "$REMOTE_MD5" ]; then
  echo "✓ 文件校验一致（md5 $LOCAL_MD5）"
else
  echo "✗ 校验不一致，请检查上传"; exit 1
fi
ssh -o BatchMode=yes "$SERVER" 'curl -s -o /dev/null -w "✓ 公网 /kb/ HTTP %{http_code}\n" http://60.205.204.162/kb/'
