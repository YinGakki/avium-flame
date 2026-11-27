#!/bin/bash
cd /root/android/avium || exit 1
LOG=/root/build-v3-progress.log
DEF=kernel/google/msm-4.14/arch/arm64/configs/floral_defconfig
BAK=/root/floral_defconfig.v3.bak
cp "$DEF" "$BAK"
restore_defconfig(){ cp "$BAK" "$DEF"; echo "=== DEFCONFIG RESTORED $(date) ===" >> "$LOG"; }
trap restore_defconfig EXIT
sed -i 's/^CONFIG_KSU=y/# CONFIG_KSU is not set/; s/^CONFIG_KSU_TAMPER_SYSCALL_TABLE=y/# CONFIG_KSU_TAMPER_SYSCALL_TABLE is not set/' "$DEF"
echo "=== BUILD V3 START $(date) ===" > "$LOG"
echo 'KSU disabled for clean payload boot' >> "$LOG"
export PATH=/root/git-repo:$PATH
mkdir -p /root/.ccache
export USE_CCACHE=1 CCACHE_DIR=/root/.ccache CCACHE_MAXSIZE=20G
ccache -M 20G >> "$LOG" 2>&1
export GOGC=50
export GOMEMLIMIT=12GiB
set +u
source build/envsetup.sh >> "$LOG" 2>&1
lunch lineage_flame-bp4a-userdebug >> "$LOG" 2>&1
lrc=$?
echo "lunch_rc=$lrc" >> "$LOG"
[ $lrc -eq 0 ] || exit 1
echo '--- m bacon -j8 ---' >> "$LOG"
m bacon -j8 >> "$LOG" 2>&1
brc=$?
echo "=== BUILD V3 END rc=$brc $(date) ===" >> "$LOG"
ls -lh out/target/product/flame/*.zip out/target/product/flame/boot.img out/target/product/flame/dtbo.img >> "$LOG" 2>&1
exit $brc