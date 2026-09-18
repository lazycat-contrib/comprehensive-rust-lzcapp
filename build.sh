#!/usr/bin/env bash
# comprehensive-rust 静态站构建：clone 上游 → mdbook 0.5.3 多语言构建 → site/
# 语言：en（根）+ zh-CN / zh-TW / ja / ko
set -euo pipefail

VERSION="${LAZYCAT_VERSION:-${VERSION:-}}"
echo "==> building comprehensive-rust version: ${VERSION:-<default branch>}"

rm -rf .upstream book site
if [ -n "$VERSION" ]; then
  if ! git clone --depth 1 --branch "$VERSION" https://github.com/google/comprehensive-rust.git .upstream 2>/dev/null; then
    echo "==> tag $VERSION not found, falling back to default branch"
    git clone --depth 1 https://github.com/google/comprehensive-rust.git .upstream
  fi
else
  git clone --depth 1 https://github.com/google/comprehensive-rust.git .upstream
fi

# ---- 工具链 ----
# mdbook 0.5.3（与仓库 mdbook-course/mdbook-exerciser 的协议版本配套）
if ! command -v mdbook >/dev/null 2>&1 || [ "$(mdbook --version | awk '{print $2}')" != "v0.5.3" ]; then
  curl -fsSL "https://github.com/rust-lang/mdbook/releases/download/v0.5.3/mdbook-v0.5.3-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /tmp/mdbook-bin --strip-components=1 2>/dev/null || {
      mkdir -p /tmp/mdbook-bin && curl -fsSL "https://github.com/rust-lang/mdbook/releases/download/v0.5.3/mdbook-v0.5.3-x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /tmp/mdbook-bin
    }
  export PATH="/tmp/mdbook-bin:$PATH"
fi
mdbook --version

# onig_sys（gettext 依赖）在较新 GCC 下编译失败，统一使用系统 libonig
sudo apt-get update -qq >/dev/null 2>&1 || true
sudo apt-get install -y -qq libonig-dev >/dev/null 2>&1 || true
export RUSTONIG_SYSTEM_LIBONIG=1
export PATH="$HOME/.cargo/bin:$PATH"

cargo install mdbook-i18n-helpers --locked --version 0.4.0 >/dev/null 2>&1
cargo install mdbook-svgbob --locked --version 0.3.1 >/dev/null 2>&1

# ---- 构建 ----
cd .upstream
cargo build --release -p mdbook-course -p mdbook-exerciser 2>&1 | tail -1
export PATH="$PWD/target/release:$PATH"

rm -rf book
mdbook build -d book
for lang in zh-CN zh-TW ja ko; do
  echo "==> building $lang"
  MDBOOK_BOOK__LANGUAGE="$lang" mdbook build -d "book/$lang"
done

# 组装 site：en 放根，翻译放子目录
rm -rf ../site
mkdir -p ../site
cp -r book/html/. ../site/
for lang in zh-CN zh-TW ja ko; do
  mkdir -p "../site/$lang"
  cp -r "book/$lang/html/." "../site/$lang/"
done
cd ..
echo "==> site built: $(du -sh site | cut -f1)"
