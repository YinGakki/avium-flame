# CHANGELOG

## v4.0-candidate — 2026-11-28
第四版候选包已编译成功，等待真机确认后定版。ROM 产物不写入 GitHub 仓库。

- **编译**：\`BUILD END rc=0 @ 2026-11-28 15:03:51\`，产物 AviumUI-16.2.2-flame-20261128_064732-Unofficial-GMS.zip（2.1G）。
- **SukiSU 管理器内置**：system_ext/app/SukiSU/SukiSU.apk（13.8MB），用 \`android_app_import\` + \`certificate: "platform"\` 预置，开箱即有。
- **主 boot 干净**：确认 \`# CONFIG_KSU is not set\`，Root 由开关刷入随包 boot_ksu.img。
- **VoLTE 真开关**：两套 MBN（中国运营商 / Pixel 原版），init 早期服务按开关 bind mount 并在 modem 加载前生效。
- **开关统一触发**：Root 与 VoLTE 共用 \`avium.switch.trigger\` 属性，避免持久属性值未变导致 init 不触发。
- **未纳入**：GPhotos 无限空间、LocalSend、MusicFree。


## v3.0-candidate — 2026-11-27
第三版候选包已编译成功，等待真机确认后定版。ROM 产物不写入 GitHub 仓库。

- **编译**：`BUILD END rc=0 @ 2026-11-27 08:09:43`，产物为 2.1G GMS 版本；主 boot 已确认 `CONFIG_KSU is not set`。
- **Root 开关**：两个 boot 镜像随 ROM 打包到 `system_ext/etc/avium/boot/`，不再需要 recovery 阶段额外复制。
- **VoLTE**：新增真开关所需两套 MBN（中国运营商 / Pixel 原版），init 服务按 `persist.avium.volte` 切换并清 FDR。
- **GMS**：保留 FilesPrebuilt；移除 Maps/MapsDynamite/Gmail/Scribe/Calendar。
- **其他**：Dialer 自动录音、Launcher 字母索引震动修复。
- **未纳入**：GPhotos 无限空间开关、LocalSend、MusicFree。
- **patch**：更新 07-vendor-avium、10-featuresettings；新增 scripts/prepare-volte-mbn-sets.sh。


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
