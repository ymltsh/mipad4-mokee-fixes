#!/system/bin/sh
MODDIR=${0%/*}
TARGET=/vendor/bin/hw/android.hardware.light@2.0-service.xiaomi_clover
EXPECTED=69e84158bfec5850eb06b98f34dfb715b8fac5db039701af7b46ddc0c8f100ef
exec >> "$MODDIR/post-fs-data.log" 2>&1
date
[ -f "$MODDIR/light-hal" ] || exit 1
[ "$(sha256sum "$MODDIR/light-hal" | awk '{print $1}')" = "$EXPECTED" ] || exit 1
chown 0:2000 "$MODDIR/light-hal" || exit 1
chmod 755 "$MODDIR/light-hal" || exit 1
chcon u:object_r:hal_light_default_exec:s0 "$MODDIR/light-hal" || exit 1
mount --bind "$MODDIR/light-hal" "$TARGET" || exit 1
# A bind from /data inherits nosuid, which also suppresses SELinux domain transitions.
# Change only this executable's bind mount, keeping it read-only and nodev.
if ! /data/adb/magisk/busybox mount -o remount,bind,ro,suid,nodev "$TARGET" "$TARGET"; then
    umount "$TARGET"
    exit 1
fi
ls -lZ "$TARGET"
