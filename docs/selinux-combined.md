# 严格模式配套修复：亮度、皮套、开机后切严格三合一

[下载模块](../downloads/MiPad4-SELinux-Fixes-Combined-v1.0.0.zip)，模块 ID：`mipad4_selinux_fixes`。

这是 SELinux 配套模块，不是此前只包含锁屏旋转与桌面底栏的布局整合模块。

## 三项功能

1. **亮度**：沿用已验证的原 HAL 执行标签修复。安装时从设备复制原二进制，字节不变；启动时以正确标签只读绑定到原服务路径，使服务进入 `hal_light_default` 域。
2. **皮套**：为 `folio_daemon` 补齐 uinput 访问、Binder 与系统服务查找、传感器事件文件描述符和事件通道读写权限。保留原域，不将该服务设为宽限，不添加通配符放行。
3. **开机后切严格**：等 `sys.boot_completed=1` 后再等待 30 秒，确认亮度和皮套服务正常，再执行一次 `setenforce 1`。不改早期启动参数，后续手动切模式不会被循环强制覆盖。

## 为什么皮套会失效

严格模式下，原皮套服务先因 `/dev/uinput` 权限不足反复退出。补齐创建虚拟输入设备的权限后，还缺少访问 sensorservice、传递 Binder 对象与使用事件通道的权限。

即使进程已经运行、霍尔传感器也注册成功，没有事件通道读写权限仍会积压事件，实际合盖不会息屏。因此本次不仅检查服务状态，也验证了实际合盖、开盖。

完整权限在 [sepolicy.rule](../modules/selinux-fixes/sepolicy.rule)，只涉及 folio_daemon 的输入设备、Binder、服务查找与传感器通信。没有放行其他应用的拒绝记录。

## 适配与验证

适配 Mi Pad 4 (`clover`)、魔趣 Android 10 / API 29。安装脚本核对原亮度与皮套服务的 SHA-256；不同服务版本会拒绝安装。

2026-10-15 已在实机完成合并安装及最终重启验证：

- SELinux 为 Enforcing，ADB 与 Root 可连接。
- 亮度服务域为 `hal_light_default`，原亮度修复保留。
- 皮套服务域为 `folio_daemon`，持续运行；传感器事件缓存为 0。
- 日志记录 `Sent lid closed event`、`Sent lid open event`；系统息屏原因是 `lid_switch`。
- 用户确认合盖息屏、开盖亮屏正常。
- 旧亮度、延迟严格模块已禁用，保留备份，由本模块接管。

这不是对整台 ROM 所有功能完成严格模式审计。AudioHQ 启动时的 `setenforce 0` 保持原样，晚启动的本模块再按配置切严格。

## 安装与迁移

在 Magisk App 安装此 ZIP，然后重启。不要同时启用旧的 `mipad4_light_hal_label_fix`、`mipad4_late_enforcing` 或其他重复皮套修复模块。先禁用它们，再启用此组合模块。

锁屏旋转和桌面底栏模块可继续使用，它们不在本包中，也不与本包冲突。安装包不包含系统原 HAL、用户 Demo APK、设备备份或密钥。

## 回滚

在 Magisk 禁用此组合模块并重启。如果迁移前使用独立亮度或延迟严格模块，可按原状态重新启用它们，再重启。旧方案不包含本次皮套权限修复。

当前运行中需要立即退出严格模式，可执行 `adb -s <设备序列号> shell su -c 'setenforce 0'`。它只改变当前模式；要避免下次开机再次切严格，应先禁用本模块。

无法进入桌面时，可在 TWRP 解密、挂载 `/data` 后，在 `/data/adb/modules/mipad4_selinux_fixes/` 创建空文件 `disable`，再重启。无需格式化数据。
