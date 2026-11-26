#!/bin/bash
# Build both boot images used by the ROM root switch.
# Run from /root/android/avium after lunch.
set -e
DEF=kernel/google/msm-4.14/arch/arm64/configs/floral_defconfig
BAK=${DEF}.bak-release
OUT=out/target/product/flame/boot.img
DST=vendor/avium/prebuilt/common/etc/avium/boot
mkdir -p "$DST"
cp "$DEF" "$BAK"
echo '=== build KSU boot ==='
m bootimage -j8
cp "$OUT" "$DST/boot_ksu.img"
echo '=== build default boot (KSU disabled) ==='
sed -i 's/^CONFIG_KSU=y/# CONFIG_KSU is not set/; s/^CONFIG_KSU_TAMPER_SYSCALL_TABLE=y/# CONFIG_KSU_TAMPER_SYSCALL_TABLE is not set/' "$DEF"
m bootimage -j8
cp "$OUT" "$DST/boot_default.img"
echo '=== KSU disabled for main ROM; boot payload will be clean ==='
ls -lh "$DST/boot_ksu.img" "$DST/boot_default.img"
