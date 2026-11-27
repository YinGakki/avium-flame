#!/bin/bash
# Rebuild the two VoLTE MBN sets from vendor/google/flame.
set -e
cd "${1:-/root/android/avium}"
SRC=vendor/google/flame/proprietary/vendor/rfs/msm/mpss/readonly/vendor/mbn/mcfg_sw
BASE=vendor/avium/prebuilt/common/etc/avium/volte
HERE=$(cd "$(dirname "$0")" && pwd)
rm -rf "$BASE/cn/mcfg_sw" "$BASE/stock/mcfg_sw"
mkdir -p "$BASE/cn/mcfg_sw" "$BASE/stock/mcfg_sw"
cp -a "$SRC"/. "$BASE/cn/mcfg_sw"/
cp -a "$SRC"/. "$BASE/stock/mcfg_sw"/
rm -rf "$BASE/stock/mcfg_sw/generic/mi9t"
rm -f "$BASE/stock/mcfg_sw/oem_sw.txt"
cp "$HERE/assets/mbn_sw.dig.stock" "$BASE/stock/mcfg_sw/mbn_sw.dig"
echo 'VoLTE MBN sets ready'
