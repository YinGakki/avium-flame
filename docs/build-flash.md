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
```

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
流程：固件检查 → 进 bootloader → `fastboot flash boot/dtbo` → 手动进 recovery(Factory reset/Format data → Apply from ADB) → `adb sideload AviumUI-*.zip`。
详细见 scripts/flash-aviumui.ps1 内注释与 PORTING 文档。

## 五、已知坑
- 分区裁剪必须改源头 mk（PRODUCT_PACKAGES 删行），lineage_flame.mk 末尾 filter-out 对 GMS 无效。
- 首次刷完新系统 USB 调试默认关闭，adb 暂时连不上属正常。
