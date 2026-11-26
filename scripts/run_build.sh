#!/bin/bash
export PATH=/root/git-repo:$PATH
cd /root/android/avium || exit 1
LOG=/root/build-progress.log
echo "=== BUILD START $(date) ===" > $LOG
# ccache 已迁回 WSL 本地 ext4 (2026-11-23, 9p NTFS 上海量小文件操作过慢), 上限 20G
mkdir -p /root/.ccache
export USE_CCACHE=1 CCACHE_DIR=/root/.ccache CCACHE_MAXSIZE=20G
ccache -M 20G >> $LOG 2>&1
# 降低 soong(Go) 内存峰值, 避免全量分析时 swap 抖动卡死 (牺牲少量速度)
export GOGC=50
export GOMEMLIMIT=12GiB
# 前置: 设备树配置 WITH_GMS
grep -q 'WITH_GMS := true' device/google/coral/lineage_flame.mk && echo 'GMS configured OK' >> $LOG || { echo 'MISSING WITH_GMS' >> $LOG; exit 1; }
for d in vendor/pixel/gms vendor/pixel/clocks vendor/pixel/sounds vendor/pixel/gsans; do [ -d "$d" ] || { echo "MISSING $d" >> $LOG; exit 1; }; done
echo 'GMS dirs OK' >> $LOG
echo '--- breakfast/lunch ---' >> $LOG
set +u
source build/envsetup.sh >> $LOG 2>&1
lunch lineage_flame-bp4a-userdebug >> $LOG 2>&1 || lunch lineage_flame-userdebug >> $LOG 2>&1
lrc=$?
echo "lunch_rc=$lrc" >> $LOG
[ $lrc -eq 0 ] || { echo 'LUNCH FAILED' >> $LOG; exit 1; }
if [ -f scripts/prepare-avium-boot-images.sh ]; then
  echo '--- prepare avium boot images ---' >> $LOG
  bash scripts/prepare-avium-boot-images.sh >> $LOG 2>&1 || { echo 'BOOT IMAGE PREP FAILED' >> $LOG; exit 1; }
fi
echo '--- m bacon -j8 ---' >> $LOG
m bacon -j8 >> $LOG 2>&1
brc=$?
echo "=== BUILD END rc=$brc $(date) ===" >> $LOG
ls -lh out/target/product/flame/*.zip out/target/product/flame/boot.img out/target/product/flame/dtbo.img >> $LOG 2>&1