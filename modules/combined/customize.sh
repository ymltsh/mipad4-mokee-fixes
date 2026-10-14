#!/system/bin/sh
[ "$BOOTMODE" = true ] || abort "Install through the Magisk app, not recovery."
[ "$(getprop ro.product.device)" = clover ] || abort "This module is for Mi Pad 4 (clover)."
[ "$API" = 29 ] || abort "This module is validated only on Android 10 / API 29."

APK=/system/product/priv-app/Lawnchair/Lawnchair.apk
[ -f "$APK" ] || abort "Built-in Lawnchair APK was not found."
EXPECTED=ab56bf7b54d4587d081e9ed8edf18af05531b6ba59bb471aa1cf2fee49eb695c
ACTUAL=$(sha256sum "$APK" | awk '{print $1}')
[ "$ACTUAL" = "$EXPECTED" ] || abort "Unverified Lawnchair version. Compare resources before installing."

ui_print "Original Launcher APK and desktop database are preserved."
ui_print "Reboot to apply. Disable this module and reboot to roll back."
