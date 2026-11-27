# 构建与刷机说明（Pixel 4 / flame）

> 基于 WSL2 + Ubuntu，源码树约 286GB，内存 18GB（-j8 谨慎）。以下为精简流程。

## 一、同步源码
```bash
repo init -u https://github.com/AviumUI/android_manifests -b <分支>
# 放入本仓库 manifest：
cp manifest/manifest-snapshot.xml .repo/manifests/
cp manifest/local_manifests/*.xml .repo/local_manifests/
repo sync -c -j8
```

## 二、应用本地改动补丁
对每个仓库 `git am` 对应 patch（顺序无强制）：
```bash
git -C build/soong am ../../patches/01-build-soong.patch
git -C vendor/pixel/gms am ../../patches/02-vendor-pixel-gms.patch
git -C vendor/google/flame am ../../patches/03-vendor-google-flame.patch
git -C device/google/coral am ../../patches/04-device-coral.patch
git -C vendor/lineage am ../../patches/05-vendor-lineage.patch
git -C kernel/google/msm-4.14 am ../../patches/06-kernel-ksu.patch
git -C vendor/avium am ../../patches/07-vendor-avium.patch
git -C packages/apps/Launcher3 am ../../patches/08-launcher3.patch
git -C packages/apps/Dialer am ../../patches/09-dialer.patch
git -C packages/apps/FeatureSettings am ../../patches/10-featuresettings.patch
```

VoLTE 两套 MBN 配置由 vendor 原始树生成，执行：
```bash
bash scripts/prepare-volte-mbn-sets.sh /root/android/avium
```
Root 开关的两个 boot 镜像由 `scripts/prepare-avium-boot-images.sh` 生成；随后用 `scripts/run_build.sh` 或手动 `m bacon -j8` 编译。

KernelSU 源码由 `manifest/local_manifests/pixel.xml` 拉取到 `kernel/google/msm-4.14/KernelSU`，分支为 `builtin-new`。
Root 开关需要两个 boot 镜像。先用 `scripts/prepare-avium-boot-images.sh` 生成 `boot_ksu.img` 与 `boot_default.img`，脚本会把它们放入 `vendor/avium/prebuilt/common/etc/avium/boot/`，并让 `floral_defconfig` 保持 KSU 关闭，因此主 ROM 的 `boot.img` 是干净默认 boot。随后 `m bacon` 会把两个 boot 镜像打包进 `system_ext`，Root 开关开启时再刷入 KSU boot。GitHub patch 不包含这两个二进制镜像。

## 三、编译
```bash
source build/envsetup.sh
lunch lineage_flame-bp4a-userdebug
m bacon -j8
```
产物在 `out/target/product/flame/`：`AviumUI-*.zip`、`boot.img`、`dtbo.img`。
（本仓库 scripts/run_build.sh 是自动化封装，纯参考。）

## 四、刷机（Windows PowerShell）
前置：官方 Android 13 固件基座、bootloader 已解锁、platform-tools(adb/fastboot) 已入 PATH。
快速用法（产物与本脚本同目录）：
```powershell
powershell -ExecutionPolicy Bypass -File .\flash-aviumui.ps1
```
流程：固件检查 → 进 bootloader → `fastboot flash boot/dtbo` → 手动进 recovery(Factory reset/Format data → Apply from ADB) → `adb sideload AviumUI-*.zip`。两个 boot 镜像已经随 ROM 打包，不再需要 recovery 阶段额外 `adb push`。
详细见 scripts/flash-aviumui.ps1 内注释与 PORTING 文档。

## 五、已知坑
- 分区裁剪必须改源头 mk（PRODUCT_PACKAGES 删行），lineage_flame.mk 末尾 filter-out 对 GMS 无效。
- 首次刷完新系统 USB 调试默认关闭，adb 暂时连不上属正常。
