# 消息写操作

所有本节命令均为写操作，**禁止** `--read-only`。

## 编辑

```bash
wacli --json messages edit --chat <CHAT> --id <MSG_ID> --message "<NEW_TEXT>"
```

失败模式：`message too old to edit` → 告知用户编辑窗口已过期。

## 删除

```bash
wacli --json messages delete --chat <CHAT> --id <MSG_ID> [--for-everyone]
```

## 撤回

```bash
wacli --json messages revoke --chat <CHAT> --id <MSG_ID>
```

## 转发

```bash
wacli --json messages forward --chat <SOURCE_CHAT> --id <MSG_ID> --to <RECIPIENT>
```
