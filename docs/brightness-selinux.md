# 严格模式下系统亮度失效的修复

Mi Pad 4 魔趣 Android 10 上，Root 直接写背光节点有效，但系统亮度滑块在 Enforcing 下失效。

## 原因

原亮度服务 `/vendor/bin/hw/android.hardware.light@2.0-service.xiaomi_clover` 被标记为 `vendor_file`，进程错误地运行在 `init` 域。

设备的 `vendor_file_contexts` 匹配了 `xiaomi_sdm660` 等服务名称，却未匹配实际的 `xiaomi_clover`。日志因此出现两类拒绝：`system_server -> init` 的 Binder call，以及 `init -> sysfs_graphics` 的 brightness open/write。

系统已有 `hal_light_default_exec -> hal_light_default` 域转换、系统调用亮度 HAL 和 HAL 写背光节点的权限。无需给 init 增加宽泛 allow 规则。

提供的亮度 Demo 使用 `su` 与 `echo` 直接写入硬件节点，绕过系统亮度服务，因此能在严格模式下控制亮度。

## 模块实现

[下载独立模块](../downloads/MiPad4-Light-HAL-Label-Fix-v1.0.0.zip)。模块 ID：`mipad4_light_hal_label_fix`。

安装时校验设备为 clover、API 为 29、原 HAL 的 SHA-256 为 `69e84158bfec5850eb06b98f34dfb715b8fac5db039701af7b46ddc0c8f100ef`，再从使用者设备复制该原服务。安装包不分发原 HAL 二进制。

启动时给副本设置 `hal_light_default_exec` 标签，并只读绑定挂载到原服务路径。来自 `/data` 的绑定挂载会继承 nosuid，这也会阻止 SELinux 域转换；模块仅对这一服务文件的绑定挂载解除 nosuid，保留只读和 nodev。未设置 setuid 文件位。若服务提前启动，模块重启它，使进程进入 `hal_light_default` 域。

不新增 allow / permissive 策略，不改变全局 SELinux 模式，不直接修改 vendor 分区，不刷 boot。

## 验证

2026-10-14 实时修复与模块安装后的重启测试均通过。临时 Enforcing 下，用系统设置将亮度设为 80、120，硬件背光节点分别返回 1284、1927；服务运行在 hal_light_default 域，测试窗口没有新的 AVC 拒绝。原服务字节校验值不变，用户确认问题解决。

测试结束已恢复原有全局模式与亮度。验证范围只覆盖系统亮度控制，不代表整台 ROM 所有功能均可长期运行在 Enforcing。

另外发现 AudioHQ 模块的 service.sh 含 `setenforce 0`，会在启动时强制宽限模式。此亮度模块不改动 AudioHQ，也不会主动切换全局严格模式。

## 安装与回滚

在 Magisk App 安装 ZIP 后重启。该亮度模块可与锁屏旋转、桌面底栏模块或旧两项整合模块同时使用，它们不修改同一目标。

回滚：在 Magisk 中禁用 **Mi Pad 4 Light HAL SELinux Label Fix**，再重启。原文件与标签会恢复，不会清空任何桌面数据。

不能进入系统时，用 TWRP 解密并挂载 `/data`，在 `/data/adb/modules/mipad4_light_hal_label_fix/` 内创建空文件 `disable`，再重启。无需格式化数据。

源码位于 [modules/light-hal-label-fix](../modules/light-hal-label-fix/)，只有配置与脚本，没有 Demo APK、系统原二进制或设备日志。
