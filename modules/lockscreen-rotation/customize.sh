#!/system/bin/sh
[ "$BOOTMODE" = true ] || abort "Install through the Magisk app, not recovery."
[ "$(getprop ro.product.device)" = clover ] || abort "This module is for Mi Pad 4 (clover)."
[ "$API" = 29 ] || abort "This module is validated only on Android 10 / API 29."

ui_print "Original Launcher APK and desktop database are preserved."
ui_print "Reboot to apply. Disable this module and reboot to roll back."
