---
name: whatsapp
description: |
  当用户提到 WhatsApp、wacli、"发 WhatsApp 消息"、"WhatsApp CLI" 时必须使用本 skill。
  也覆盖隐式场景："给妈妈发条消息"、"搜索我的聊天记录"、"备份 WhatsApp"、"列出我的 WhatsApp 群组"、"下载 WhatsApp 媒体"。
  覆盖操作动词：发送、搜索、同步、导出、备份、列出、管理联系人/群组/频道。
  任何可通过 wacli CLI 完成的 WhatsApp 相关任务都应使用本 skill，即使用户没有明确说出 wacli。
triggers:
  - whatsapp
  - wacli
  - "send whatsapp message"
  - "whatsapp cli"
  - "发 WhatsApp"
  - "搜索我的聊天记录"
  - "备份 WhatsApp"
  - "列出 WhatsApp 群组"
  - "下载 WhatsApp 媒体"
scope: project
---
