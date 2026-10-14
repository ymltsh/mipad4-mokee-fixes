# Mi Pad 4 魔趣 Android 10 修复包

保留系统原桌面与 Quickstep 动画集成，通过 Magisk 解决锁屏不能横屏、横屏桌面 Dock 跑到侧面的问题，并记录 Zygisk 开启后 ADB 认证失败的修复过程。

## 下载

最新发布：[v1.2.0](https://github.com/ymltsh/mipad4-mokee-fixes/releases/tag/v1.2.0)，新增已实机验证的“亮度 + 皮套 + 开机后切严格”三合一模块。原布局整合模块仍只包含锁屏和桌面两项。

| 包 | 用途 |
| --- | --- |
| [整合 Magisk 模块](downloads/MiPad4-MoKee-Fixes-v1.0.0.zip) | 锁屏旋转 + 原桌面底部 Dock |
| [锁屏旋转模块](downloads/MiPad4-Lockscreen-Rotation-v1.0.0.zip) | 只启用锁屏旋转 |
| [桌面底栏模块](downloads/MiPad4-Lawnchair-BottomDock-v1.0.0.zip) | 只修复原桌面横屏 Dock |
| [严格模式三合一模块](downloads/MiPad4-SELinux-Fixes-Combined-v1.0.0.zip) | 亮度标签、皮套息屏和开机后切严格；推荐用于本次验证环境 |
| [严格模式亮度模块](downloads/MiPad4-Light-HAL-Label-Fix-v1.0.0.zip) | 修复原亮度服务 SELinux 标签 |
| [源码与模块合集](downloads/mipad4-mokee-fixes-source-v1.2.0.zip) | 文档、源码、构建脚本、全部独立模块及旧整合包 |

进入文件页面后点击 **Raw / Download raw file** 下载。各功能模块 ZIP 在 Magisk App 中安装；源码与模块合集不是可直接安装的 Magisk 模块。

## 适用环境

- Mi Pad 4，设备代号 `clover`，魔趣 Android 10 / API 29。
- 验证系统：`mokee_clover-userdebug 10 QQ3A.200805.001`，2022-09-24 构建。
- 系统内置 Lawnchair **10.0 Alpha 8**，包名 `ch.deletescape.lawnchair.ci`。
- 验证 Magisk 30.7，Shamiko v1.2.5.1 (417)。两项布局模块本身不依赖 Zygisk 或 Shamiko。
- 桌面模块检查目标 APK SHA-256，拒绝未核对过的版本，避免误用于不同桌面。

## 安装与回滚

严格模式三合一包的迁移、验证和回滚见 [三合一说明](docs/selinux-combined.md)。安装前禁用旧亮度、开机严格及重复皮套模块；可与原锁屏、桌面布局修复同时使用。下面的“二选一”仅指布局模块。

1. 保留可用 ADB / TWRP，备份桌面布局。在 Magisk App 选择所需 ZIP 安装。
2. **布局整合模块与两项布局独立模块二选一**；亮度模块可同时使用。若已安装本项目两项布局独立模块，先禁用它们，再安装整合模块。
3. 重启。保持自动旋转开启，在锁屏和桌面分别横放、竖放检查。
4. 回滚时在 Magisk 中禁用对应模块，再重启；不会清空桌面数据库。

若不能进入桌面，在 TWRP 解密并挂载 `/data` 后，在相应 `/data/adb/modules/<模块 ID>/` 内创建空文件 `disable`，再重启。不要格式化数据。

模块 ID：整合 `mipad4_mokee_fixes`；锁屏 `mipad4_lockscreen_rotation`；桌面 `mipad4_lawnchair_bottomdock`。

## 实现

- 锁屏：`system.prop` 设置 `lockscreen.rot_override=true`，调用魔趣已有旋转能力。
- 桌面：仅覆盖 `hotseat_transpose_layout_with_orientation=false`。原桌面只有 `sw720dp` 才关闭侧栏，而 Mi Pad 4 当前最小宽度为 600dp，因此横屏误用侧栏布局。
- 资源覆盖 APK 位于 Magisk 模块的 `system/product/overlay/`。它没有 DEX 代码，原桌面 APK、签名、包名和动画代码保持不变。
- 不直接写入 system / product，不刷 boot，不更换 Launcher，不调整屏幕密度。

严格模式下系统亮度失效的原因、验证和回滚见 [亮度 SELinux 修复说明](docs/brightness-selinux.md)。此模块不改变全局 SELinux 模式，可与原布局模块同时使用。

Zygisk 的 ADB 认证故障不能用通用公钥模块解决，见 [Zygisk 与 ADB 排障记录](docs/zygisk-adb.md)。

## 验证范围

2026-10-14 在上述设备实测两项独立补丁：锁屏和解锁界面正常旋转；桌面横屏 `isTransposed=false`，Dock 位于底部；原桌面 APK 哈希不变；多次重启后仍生效；用户确认问题解决。原有动画集成代码未改动，动画体验由实际操作确认。

整合包由同一已验证属性和资源覆盖组成，已校验结构与校验和；**尚未单独重新安装整合包实测**。其他 ROM、其他 Lawnchair 版本和后续系统升级不在验证范围内。

## 源码与构建

`modules/` 为模块目录，`overlay-src/` 为资源 APK 的完整源码，`tools/build.py` 从源码构建资源 APK 并重新打包模块 ZIP。需要 Python 3、JDK 17+ 和从目标 Android 10 设备取得的 `framework-res.apk`：

```powershell
adb -s <设备序列号> pull /system/framework/framework-res.apk framework-res.apk
python tools/build.py --framework framework-res.apk --java-bin "C:/path/to/jdk/bin"
```

脚本固定 Apktool 3.0.3 并验证 SHA-256，从中提取 AAPT2。签名使用本地临时生成的覆盖 APK 证书，不使用系统签名。重建后 APK 字节和校验和会因签名证书而变化。

发布文件校验见 [SHA256SUMS.txt](SHA256SUMS.txt)。仓库没有设备数据库、应用备份、个人截图、电脑授权公钥、ADB 私钥或签名私钥。

## 参考

- [魔趣锁屏旋转实现](https://github.com/MoKee/android_frameworks_base/blob/mkq-mr1/packages/SystemUI/src/com/android/systemui/statusbar/phone/StatusBarWindowController.java)
- [Android 资源覆盖 RRO](https://source.android.com/docs/core/runtime/rros)
- [Magisk 模块格式](https://topjohnwu.github.io/Magisk/guides.html)
- [ADB 安全授权](https://developer.android.com/tools/adb)

本仓库的原创配置、说明与脚本采用 MIT 许可；外部工具遵循各自许可，未随仓库分发。
