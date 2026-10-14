# Zygisk 开启后 ADB 认证失败：本次修复记录

## 现象与证据

关闭 Zygisk 时无线 ADB 正常。开启 Zygisk 后连接出现 `failed to authenticate` / `unauthorized`。端口可建立 TCP 连接，说明网络可达，不能把它直接判断为 adbd 崩溃。

设备最初 `ro.adb.secure=0`，没有 `/data/misc/adb/adb_keys`。暂停 Shamiko 后，Zygisk 库可正常载入，ADB 与 Root 均可用，崩溃日志为空。恢复 Shamiko 后，其脚本把 `ro.adb.secure` 改为 `1`、`ro.debuggable` 改为 `0`，连接进入未授权状态。

关闭 Zygisk、重启恢复后，备份授权状态，将**使用者自己这台电脑**的 ADB 公钥加入设备授权文件。再次启用 Zygisk 与 Shamiko并重启，日志记录 `Loading keys from /data/misc/adb/adb_keys` 和 `adb client authorized`。最终 Zygisk 设置为 1，zygote 已载入 libzygisk.so，Shamiko 启用，ADB 与 su 均正常。

本次主要原因是安全认证启用后缺少电脑授权，未观察到 Zygisk / adbd 崩溃。USB 实体连接没有实测；重启早期还可能短暂 offline，应在启动完成后重连。

## 优先恢复正常授权

解锁平板，确认 USB 调试开启，优先接受电脑 RSA 授权提示并选择始终允许。没有提示时，可先关闭 Zygisk并重启恢复连接，再检查模块影响、授权服务及设备日志。

本次因授权提示未能解决，采用 Root 写入当前电脑公钥。复用这一路径前应备份现有授权文件，保留其他电脑的授权，并核对公钥来自正在使用的电脑。常见公钥位置是 Windows `%USERPROFILE%/.android/adbkey.pub`，实际位置可能受环境变量影响。

设备文件 `/data/misc/adb/adb_keys` 的属主为 `system:shell`（1000:2000），权限 640，SELinux 类型 `adb_keys_file`；用 `restorecon` 恢复标签。需要的是 `.pub` 公钥，**不要把不带 .pub 的私钥复制到设备或仓库**。不应改为关闭安全认证。

## 离线采集与回滚

开启 Zygisk前保存 Magisk设置、模块启用状态和授权文件；准备平板上手动关闭 Zygisk并重启的恢复途径。可用设备端启动脚本把 `logcat -b all -d`、`logcat -b crash -d`、相关属性、进程状态保存到本地，恢复 ADB后取回，避免只依赖实时连接。

本次测试曾用临时 Magisk service.d 脚本把下一次启动的 Zygisk 设置恢复为 0；验证成功后已移除。该措施不保证早期启动异常也能恢复，仍须保留 TWRP等后路。

撤销修复时先关闭 Zygisk并重启确认连接恢复，再从授权文件中仅移除本次新增公钥，保留其他授权。若保持安全认证开启却移除唯一电脑公钥，这台电脑会重新变为未授权。

这里发布的是排障方法与脱敏记录，不是自动注入公钥或关闭认证的模块。
