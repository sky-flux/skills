# 消息查询操作（读操作）

所有本节命令均为读操作，必须追加 `--read-only`。

## 搜索

```bash
wacli --json --read-only messages search "<QUERY>" \
  [--chat <CHAT>] \
  [--from <JID>] \
  [--type text|image|video|audio|document] \
  [--after <ISO8601>] \
  [--before <ISO8601>] \
  [--limit <N>] \
  [--forwarded] \
  [--has-media] \
  [--starred]
```

## 列表

```bash
wacli --json --read-only messages list \
  [--chat <CHAT>] \
  [--sender <JID>] \
  [--from-me] \
  [--from-them] \
  [--after <ISO8601>] \
  [--before <ISO8601>] \
  [--limit <N>] \
  [--forwarded] \
  [--starred] \
  [--asc]
```

## 单条展示

```bash
wacli --json --read-only messages show --chat <CHAT> --id <MSG_ID>
```

## 上下文

```bash
wacli --json --read-only messages context --chat <CHAT> --id <MSG_ID> [--limit <N>]
```

## 导出

```bash
wacli --json --read-only messages export [--chat <CHAT>] --output <PATH> [--limit <N>]
```

## 收藏消息

```bash
wacli --json --read-only messages starred [--chat <CHAT>] [--limit <N>]
```
