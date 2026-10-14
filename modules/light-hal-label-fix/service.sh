#!/system/bin/sh
MODDIR=${0%/*}
exec >> "$MODDIR/service.log" 2>&1
date
TARGET=/vendor/bin/hw/android.hardware.light@2.0-service.xiaomi_clover
ls -lZ "$TARGET" | grep -q 'hal_light_default_exec' || exit 1
# Cover light services started before the post-fs-data bind mount was installed.
if ! ps -AZ | grep 'android.hardware.light@2.0-service.xiaomi_clover' | grep -q 'u:r:hal_light_default:s0'; then
    setprop ctl.restart vendor.light-hal-2-0
fi
sleep 3
ps -AZ | grep 'android.hardware.light@2.0-service.xiaomi_clover'
