# 平台支持

KGMusic 当前发布 Android、Linux x86_64 和 Windows x64。三个目标共用 Flutter UI、
领域模型和 Rust Lite SDK Bridge；媒体控制和窗口行为按平台接入。

## Android

- 使用 `audio_service` 提供通知、锁屏和耳机/蓝牙媒体控制。
- Manifest 声明网络、唤醒锁、媒体前台服务和通知权限；Android 13 及以上应允许通知，
  才能稳定显示媒体会话。
- 明文网络默认禁止，仅为 `kugou.com` 及其子域和本地回环地址放行。
- 设备身份从 Android 平台通道采集；无法读取 `ANDROID_ID` 时使用安全存储中的稳定安装
  ID。不要在 Dart 层伪造或持久化第三方设备指纹。

构建调试 APK：

```bash
flutter build apk --debug
```

正式构建必须配置上传密钥，详见[发布](releasing.md)。

## Linux

- Flutter runner 基于 GTK 3；支持 GNOME、X11 与 Wayland 常规窗口环境。
- `just_audio_media_kit` 提供桌面音频后端，`audio_service_mpris` 暴露 MPRIS 媒体控制。
- 关闭窗口默认隐藏到系统托盘；托盘菜单可显示窗口、控制播放与彻底退出。窗口位置、尺寸
  和最大化状态会持久化。
- 运行时依赖 Secret Service、`libmpv2`、GTK 3 和 Ayatana AppIndicator（或兼容
  AppIndicator）。DEB 的依赖声明位于 `packaging/linux/control`。

开发构建：

```bash
flutter build linux --release
```

发布时脚本会基于 Flutter bundle 创建 DEB 和 AppDir，CI 再使用校验过的 `linuxdeploy`
生成 AppImage。DEB 和 AppImage 都不内置 libmpv，运行前需由系统提供 `libmpv.so.2`
（Debian/Ubuntu 包名为 `libmpv2`）。不要手动向 `build/` 目录提交产物。

## Windows

- `just_audio_windows` 使用 Windows Runtime `MediaPlayer` 提供音频后端，
  `audio_service_win` 接入 SMTC。Windows 包不再携带预编译 libmpv/FFmpeg DLL。
- 与 Linux 一样，关闭窗口会隐藏到托盘；媒体键、通知区域和应用内播放器共享同一播放状态。
- Runner 只声明 x64 发布产物。ARM64 不在当前 CI 的发布范围内。
- 可播放格式取决于目标 Windows 版本安装的 Media Foundation 解码能力；部分 FLAC、
  Hi-Res 或 DSD 编码可能无法由系统后端解码，此时应切换到系统支持的较低音质。

开发构建：

```powershell
flutter build windows --release
```

创建 MSIX：

```powershell
dart run msix:create --build-windows false
```

正式签名需要 PFX 证书和与证书 Subject 完全一致的 Publisher。测试签名 MSIX 不能被当作
受信任的公开安装包；详见[发布](releasing.md)。

## 未发布目标

虽然 Flutter Rust Bridge 插件声明了其他宿主平台，iOS、macOS 与 Web 没有在本仓库的
发布流程中构建或验证。新增目标前，应先评估媒体控制、安全存储、Rust 产物和 CI 签名，
并补充相应的测试与文档。
