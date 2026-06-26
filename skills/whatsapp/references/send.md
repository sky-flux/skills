# 发送消息与投票

所有 `send` 子命令均为写操作，**禁止** `--read-only`。

## 文本

```bash
wacli --json send text --to <RECIPIENT> --message "<TEXT>"
```

## 文件 / 图片 / 视频 / 音频 / 文档

```bash
# 发送前验证文件存在：test -f <PATH>
wacli --json send file --to <RECIPIENT> --file <PATH> [--caption "<CAPTION>"]
```

## 贴纸

```bash
wacli --json send sticker --to <RECIPIENT> --file <PATH>
```

## 语音

```bash
wacli --json send voice --to <RECIPIENT> --file <PATH>
```

## 反应

```bash
wacli --json send react --to <RECIPIENT> --id <MSG_ID> --reaction "<EMOJI>"
```

## 投票

```bash
# 创建投票（2-12 个选项，重复 --option）
wacli --json send poll --to <RECIPIENT> --question "<QUESTION>" --option "opt1" --option "opt2" [--multi N]

# 投票（写操作）
wacli --json poll vote --to <CHAT> --id <MSG_ID> --option "<OPTION>" [--sender <JID>]
```

## 投票列表（只读）

```bash
wacli --json --read-only polls list
```

## 状态广播

```bash
wacli --json send status --text "<TEXT>"
wacli --json send status --file <PATH> [--caption "<CAPTION>"]
```

## 按钮 / 列表选择

```bash
wacli --json send select --to <RECIPIENT> --id <MSG_ID> --label "<TEXT>"
wacli --json send select --to <RECIPIENT> --id <MSG_ID> --button-id "<ID>"
wacli --json send select --to <RECIPIENT> --id <MSG_ID> --index <N>
```
