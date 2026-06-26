# 资料、在线状态、诊断与 Store 维护

## 个人资料

写操作（这些命令拉取实时资料数据并可能更新本地 store）：

```bash
wacli --json profile business --jid <JID>
wacli --json profile get-about --jid <JID>
wacli --json profile picture-info --jid <JID>
```

写操作（修改个人资料）：

```bash
wacli --json profile remove-picture
wacli --json profile set-about --about "<ABOUT>"
wacli --json profile set-name --name "<NAME>"
wacli --json profile set-picture <PATH>
```

## 在线状态

写操作：

```bash
wacli --json presence typing --to <RECIPIENT>
wacli --json presence paused --to <RECIPIENT>
```

## 诊断

读操作：

```bash
wacli --json --read-only doctor
wacli --json --read-only store stats
wacli --json --read-only store cleanup --dry-run
wacli --json --read-only version
```

写操作：

```bash
wacli --json doctor --connect
wacli --json store cleanup
```
