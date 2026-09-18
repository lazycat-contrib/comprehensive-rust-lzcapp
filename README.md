# Comprehensive Rust (LazyCat)

Google 出品的《Comprehensive Rust 🦀》Rust 系统课程，打包为 LazyCat LPK v2 静态应用。上游项目：[google/comprehensive-rust](https://github.com/google/comprehensive-rust)（基于 [mdbook](https://github.com/rust-lang/mdbook)）。

## 部署信息

- **包名**：`cloud.lazycat.app.comprehensive-rust`
- **版本**：跟随上游 main 分支自动更新（每日 UTC 02:00 检查，北京时间 10:00）
- **类型**：纯静态站（mdbook 0.5.3 + gettext/svgbob/course 预处理器，无后端服务）
- **min_os_version**：1.5.0
- **语言**：en（根）+ zh-CN / zh-TW / ja / ko（约 150 MB）

## 自动更新机制

上游没有 release tag，`sync-upstream` job 每日比对 main 分支 HEAD commit SHA（`.upstream-sha` 记录上次构建值），变化则 bump patch（1.0.0 → 1.0.1 …）并 push 触发发布。

```
上游 google/comprehensive-rust (main)
   │  schedule 检查 HEAD SHA → 变化则 bump patch → push
   ▼
本仓库（LPK 配置 + build.sh）
   │  push 触发 → ca-x/lazycat-github-action
   │  buildscript: clone 上游 → 安装 mdbook 0.5.3 + mdbook-i18n-helpers 0.4.0
   │    + mdbook-svgbob + cargo 构建 mdbook-course/exerciser → 5 语言 mdbook build → site/
   ▼
LPK 打包（contentdir: ./site）→ GitHub Release + 喵喵商店发布
```

## 构建要点

- **版本配套**：mdbook 必须用 0.5.3（仓库的 mdbook-course 预处理器按 0.5.x 协议）；i18n-helpers 用 0.4.0
- **onig_sys 兼容**：i18n-helpers 的 onig_sys C 依赖在较新 GCC 下编译失败，统一用系统 `libonig-dev` + `RUSTONIG_SYSTEM_LIBONIG=1`
- **翻译构建**：`MDBOOK_BOOK__LANGUAGE=<lang> mdbook build -d book/<lang>`，未翻译内容自动回退英文
- **site 结构**：en 在根目录，翻译在 `/zh-CN`、`/zh-TW`、`/ja`、`/ko` 子目录

## 文件结构

```
package.yml              # 包元数据
lzc-manifest.yml         # 运行结构（file:// 静态服务）
lzc-build.yml            # 构建配置（contentdir + buildscript）
build.sh                 # CI 构建脚本（clone 上游 + mdbook 多语言）
.upstream-sha            # 上次构建的上游 commit SHA
icon.png                 # 应用图标
.github/lazycat-action.yml      # Action 配置（git 版本源 / 喵喵商店）
.github/workflows/lazycat.yml   # 上游同步 + 发布工作流
```
