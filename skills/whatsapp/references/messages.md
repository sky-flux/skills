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

## 媒体下载

`media download` 默认将媒体写入 store media 目录（写操作）。若指定 store 外部的 `--output <PATH>`，则可作为读操作并追加 `--read-only`。

### 默认输出（写操作）

```bash
wacli --json media download --chat <CHAT> --id <MSG_ID>
```

### 指定外部路径（读操作）

```bash
wacli --json --read-only media download --chat <CHAT> --id <MSG_ID> --output <PATH>
```
