#!/system/bin/sh
[ "$BOOTMODE" = true ] || abort "Install through the Magisk app."
[ "$(getprop ro.product.device)" = clover ] || abort "This module is for Mi Pad 4 (clover)."
[ "$API" = 29 ] || abort "Validated only on Android 10 / API 29."
TARGET=/vendor/bin/hw/android.hardware.light@2.0-service.xiaomi_clover
EXPECTED=69e84158bfec5850eb06b98f34dfb715b8fac5db039701af7b46ddc0c8f100ef
[ -f "$TARGET" ] || abort "Original clover light HAL not found."
[ "$(sha256sum "$TARGET" | awk '{print $1}')" = "$EXPECTED" ] || abort "Unknown light HAL version."
cp "$TARGET" "$MODPATH/light-hal" || abort "Cannot copy original light HAL."
set_perm "$MODPATH/light-hal" 0 2000 0755 u:object_r:hal_light_default_exec:s0
FOLIO=/vendor/bin/folio_daemon
[ -f "$FOLIO" ] || abort "Folio daemon not found."
[ "$(sha256sum "$FOLIO" | awk '{print $1}')" = fa7326583674d02c98a0db680b1e04613d4f7808bcf0de4b1bf1183e19896858 ] || abort "Unknown folio daemon version."
ui_print "Original executable copied unchanged; only its execution label will be corrected."
ui_print "Adds scoped folio permissions; Enforcing is enabled only after boot completion."
ui_print "Reboot to apply; disable this module and reboot to roll back."
