# 云服务器部署指南（轻量级 · 纯静态）

## 方案说明

本应用是**纯前端单文件**（index.html 内嵌全部 1498 条课程数据），无需数据库、无需 Node/Python 后端，任何静态服务器都能跑。

## 当前云服务器（60.205.204.162）的实际部署

- 应用目录：`/srv/apps/grad-timetable/app/`（index.html + manifest.webmanifest + icon.svg）
- 运行方式：docker 容器 `grad-timetable`（127.0.0.1:3901→8080），nginx 现役站点 `hackathon` 的 `location ^~ /kb/` 反代到 3901，公网入口 `http://60.205.204.162/kb/`
- **每次修改后一键发布**（构建 → 推 GitHub → 备份并上传服务器 → md5 校验）：

```bash
bash work/deploy.sh "本次修改说明"
```

- 服务器上每次发布前会自动留备份 `index.html.bak-日期时间`，回滚直接 `cp` 回去即可。

## 其他托管方式（任选其一）

### 方式 A：Nginx（服务器已有 nginx，推荐）

1. 把 `浙工商研究生课表浏览器2026秋.html` 上传到服务器，重命名为 `index.html`：

```bash
scp 浙工商研究生课表浏览器2026秋.html root@你的服务器IP:/var/www/kb/index.html
scp deploy/manifest.webmanifest deploy/icon.svg root@你的服务器IP:/var/www/kb/
```

2. 参考 `nginx.conf.sample` 配置站点（核心就一段 `location /kb/ { root /var/www; try_files $uri $uri/ /kb/index.html; }`）。

3. 手机浏览器打开 `http://IP/kb/`（或绑定域名 + HTTPS）→ 菜单选"添加到主屏幕"，即获得类原生 App 图标的全屏应用。

### 方式 B：任意静态托管（GitHub Pages / Vercel / 对象存储等）

把三个文件（index.html、manifest.webmanifest、icon.svg）拖进任意静态托管目录即可，零配置。

## 部署后独有的能力（本地 file:// 做不到的）

- **分享链接真正可用**：`#my=` 链接发给同学，点开即导入清单
- **手机主屏 App**：PWA manifest 已内置，添加到主屏幕后全屏、有图标
- **一个网址全校共用**：导师、同学、督导老师收藏同一个 URL 即可

## 数据更新（下学期新排课表发布后）

1. 把新的排课表 `.xls` 抽取为 `work/courses.json`（字段名与现有文件保持一致：开课院系/课程名称/课程性质/教室名称/主讲教师/校区名称/星期几/单双周/节次/自定义周次/选中人数）
2. 核对 `work/template.html` 里的推荐清单（RECO）与校历日期（第 1 教学周周一、"学期"文案）
3. 在项目根目录运行 `node work/build.js`——自动把课程数据注入模板，生成根目录的课表 HTML
4. 重新上传生成的 HTML 覆盖服务器上的 index.html 即可

## 安全提醒

如暴露公网，建议加 HTTPS（certbot 一条命令），并不要在页面中放任何隐私数据。
