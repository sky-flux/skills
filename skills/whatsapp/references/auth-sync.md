# 认证、账号、同步与历史回填

## 认证

```bash
# QR 配对（交互式，不加 --json）
wacli auth

# 电话码配对
wacli auth --phone <NUMBER>

# 检查认证状态（读操作）
wacli --json --read-only auth status

# 登出
wacli --json auth logout
```

## 账号管理

```bash
# 列出已配置账号（读操作）
wacli --json --read-only accounts list

# 查看账号详情（读操作）
wacli --json --read-only accounts show <NAME>

# 添加账号
wacli --json accounts add <NAME> [--store <DIR>]

# 移除账号
wacli --json accounts remove <NAME>

# 切换当前账号
wacli --json accounts use <NAME>
```

## 同步

```bash
# 持续后台同步（默认 --follow，写/网络操作）
wacli --json sync

# 一次性同步直到空闲
wacli --json sync --once

# 同步并刷新联系人/群组/频道
wacli --json sync --refresh-contacts
wacli --json sync --refresh-groups
wacli --json sync --refresh-channels

# 同步并下载媒体
wacli --json sync --download-media

# webhook 模式（写/网络操作，禁止 --read-only）
wacli --json sync --webhook <URL>
```

## 历史回填

```bash
# 查看历史覆盖情况（读操作）
wacli --json --read-only history coverage --chat <CHAT>

# 干跑回填（读操作）
wacli --json --read-only history fill --chat <CHAT> --dry-run

# 实际回填（写操作）
wacli --json history backfill --chat <CHAT>
wacli --json history fill --chat <CHAT>
```
