# CHANGELOG

## v2 recipe — 2026-11-26
第二版源码配方。ROM 产物仍不写入 GitHub 仓库。

- **功能**：KernelSU builtin-new root boot switch; China VoLTE MBN; 绝招 Root/Pixel 分组; 自动录音开关; Launcher 字母索引震动对齐返回; Dialer 自动录音开关。
- **GMS 调整**：保留 FilesPrebuilt；移除 Maps/MapsDynamite/Gmail/Scribe/Calendar。
- **Root 开关**：两个 boot 镜像随 ROM 打包到 `system_ext/etc/avium/boot/`，不再需要 recovery 阶段额外复制；开关通过 runtime trigger 强制刷新 boot 分区。
- **patch**：新增 06-kernel-ksu、07-vendor-avium、08-launcher3、09-dialer、10-featuresettings；更新 02/03。
- **manifest**：新增 SukiSU `builtin-new` 源码仓库。


## v1.0 — 2026-11-24
首个可正常刷入并使用的版本。

- **编译**：`BUILD END rc=0 @ 2026-11-24 11:26:03`；产物 `AviumUI-16.2.2-flame-20261124_025343-Unofficial-GMS.zip`（约 2.1G，含 GMS）、`boot.img`、`dtbo.img`
- **刷机**：`fastboot flash boot/dtbo` + recovery `adb sideload`，sideload exit=0，设备正常开机使用
- **本地改动（见 patches/）**：
  - `build/soong`：将 GOGC/GOMEMLIMIT 透传到 soong_build（解决低内存机器全量分析卡死）
  - `vendor/pixel/gms`、`vendor/lineage`：裁剪预置大包（Velvet/Bugle/DevicePersonalization×2/GoogleDialer/SafetyHub/FilesPrebuilt/ThemePicker/Seedvault），以适配 super 分区大小
  - `device/google/coral`：`BOARD_SUPER_PARTITION_ERROR_LIMIT` 设为 super 全量（手动刷机无需 OTA 余量）
- **已知**：默认无 root；USB 调试默认关闭；设置部分页面为 LineageOS 原生。
