#!/usr/bin/env node
/*
 * 课表页构建脚本：courses.json（原始抽取数据）→ 精简 DATA → 注入 template.html → 根目录成品 HTML
 * 用法：在项目根目录运行  node work/build.js
 * 新学期更新：先把新排课表 .xls 抽取为 work/courses.json（键名与现有文件一致），
 *            再核对 work/template.html 里的 RECO 推荐清单与校历日期，最后运行本脚本。
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const raw = JSON.parse(fs.readFileSync(path.join(ROOT, "work", "courses.json"), "utf8"));

/* 字段映射：中文原始键 → 页面精简键（与页面 JS 的读取字段一一对应） */
const MAP = {
  "开课院系": "d",
  "课程名称": "c",
  "课程性质": "n",
  "教室名称": "r",
  "主讲教师": "t",
  "校区名称": "x",
  "星期几": "w",
  "单双周": "s",
  "节次": "p",
  "自定义周次": "z",
  "选中人数": "g"
};
const DATA = raw.map(rec => {
  const o = {};
  for (const [cn, en] of Object.entries(MAP)) o[en] = rec[cn] ?? "";
  return o;
});

const template = fs.readFileSync(path.join(ROOT, "work", "template.html"), "utf8");
const marker = "/*__DATA__*/[]";
if (!template.includes(marker)) {
  console.error("template.html 中找不到数据注入点 /*__DATA__*/[]");
  process.exit(1);
}
const out = template.replace(marker, JSON.stringify(DATA));

/* 产物文件名固定为根目录的课表 HTML */
const TARGET = path.join(ROOT, "浙工商研究生课表浏览器2026秋.html");
fs.writeFileSync(TARGET, out);
console.log(`已生成 ${path.basename(TARGET)}：${DATA.length} 条课程记录，${(out.length / 1024).toFixed(0)} KB`);
