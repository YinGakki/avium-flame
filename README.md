# AviumUI for Pixel 4 (flame) — 自编译发布

本仓库是 **Google Pixel 4（代号 flame）** 上自编译 **AviumUI 16.2.2**（基于 Android 16 QPR2 / avium-16.2，设备树采用 LineageOS 官方 flame）的可复现"配方"：manifest 快照 + 改动补丁 + 构建/刷机脚本 + 文档。ROM 产物（大文件）发布在 123 云盘。

## 支持机型
- Google Pixel 4 (flame)。需官方 Android 13 固件基座（已验证 TP1A.221005.002.B2），且 bootloader 已解锁。

## 仓库内容
- `manifest/` — `manifest-snapshot.xml`(repo manifest -r 全树快照)、`local_manifests/`、`upstream-default.xml`
- `patches/` — 相对上游的本地改动（soong GOGC/GOMEMLIMIT 透传、GMS 裁剪、分区 error_limit 等）
- `scripts/` — `run_build.sh`(WSL 编译脚本)、`flash-aviumui.ps1`(Windows PowerShell 刷机脚本)
- `docs/` — 构建与刷机说明

## 版本
- **v1.0 (2026-11-24)**：首个可用版本，`AviumUI-16.2.2-flame-20261124_025343-Unofficial-GMS.zip`（带 GMS，约 2.1G）。详见 CHANGELOG.md。

## 免责声明
自编译非官方 ROM，刷机有风险、后果自负。刷机前请备份数据、确认 bootloader 状态与固件版本，并阅读 docs。

## 来源与许可
基于 AviumUI (avium-16.2) 与 LineageOS 官方 flame 设备树；Linux 内核为 GPL-2.0（对应源码见上游仓库）。本仓库仅含配置/补丁/脚本，供学习与复现。
