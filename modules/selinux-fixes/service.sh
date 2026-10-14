#!/system/bin/sh
MODDIR=${0%/*}
exec > "$MODDIR/last-boot.log" 2>&1
date
TARGET=/vendor/bin/hw/android.hardware.light@2.0-service.xiaomi_clover
if ls -lZ "$TARGET" | grep -q 'hal_light_default_exec'; then
    if ! ps -AZ | grep 'android.hardware.light@2.0-service.xiaomi_clover' | grep -q '^u:r:hal_light_default:s0'; then
        setprop ctl.restart vendor.light-hal-2-0
    fi
else
    echo "Light HAL label fix missing; automatic Enforcing skipped."
    exit 0
fi
setprop ctl.restart vendor.folio_daemon
COUNT=0
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    [ ! -f "$MODDIR/disable" ] && [ ! -f "$MODDIR/remove" ] || exit 0
    COUNT=$((COUNT + 1))
    [ "$COUNT" -le 300 ] || { echo "Boot completion timed out; Enforcing skipped."; exit 0; }
    sleep 2
done
echo "Boot complete; waiting 30 seconds before one-shot Enforcing."
sleep 30
[ ! -f "$MODDIR/disable" ] && [ ! -f "$MODDIR/remove" ] || exit 0
ps -AZ | grep 'android.hardware.light@2.0-service.xiaomi_clover' | grep -q '^u:r:hal_light_default:s0' || exit 0
[ "$(getprop init.svc.vendor.folio_daemon)" = running ] || { echo "Folio service not running; Enforcing skipped."; exit 0; }
ps -AZ | grep 'folio_daemon' | grep -q '^u:r:folio_daemon:s0' || exit 0
echo "Before: $(getenforce)"
setenforce 1 || exit 1
echo "After: $(getenforce)"
