# wacli 安装指南

## 检测

```bash
which wacli
wacli --version
```

## 安装优先级

1. **Homebrew（macOS / Linux with brew）**

```bash
brew install openclaw/tap/wacli
```

2. **Go install**

```bash
CGO_ENABLED=1 CGO_CFLAGS="-Wno-error=missing-braces" go install -tags sqlite_fts5 github.com/openclaw/wacli/cmd/wacli@latest
```

需要 Go 和 C 编译器：
- macOS: Xcode Command Line Tools
- Debian/Ubuntu: `build-essential`

3. **Build from source**

```bash
git clone https://github.com/openclaw/wacli.git
cd wacli
# 按仓库 README 执行 pnpm build 或等价的 Go build 命令
```

## 版本兼容性

- 本 skill 目标版本：`wacli` v0.11.x。
- 首次使用运行 `wacli --version`，如主/次版本不在测试范围内则警告。
- 后续版本若标志或子命令变更，先更新 `references/command-index.md` 再声明兼容。
