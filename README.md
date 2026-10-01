# KGMusic

KGMusic 是一个支持 Android、Linux 与 Windows 的 Flutter 音乐客户端，使用 Rust
`kugou_sdk = 0.2.9` 访问酷狗 Lite（概念版）接口。项目不会回退到 Standard
后端。

> KGMusic 是社区维护的非官方客户端，与酷狗音乐及其关联公司不存在隶属、授权或背书
> 关系。相关名称与商标归其权利人所有；使用者应自行遵守服务条款与所在地区的法律法规。

## 当前首轮能力

- Lite 每日推荐与歌曲搜索
- Rust 侧播放地址解析，Flutter `just_audio` 负责实际播放
- 播放器支持标准、320K、FLAC、Hi-Res 与 DSD 音质切换，并显示实际回退结果
- 完整播放失败时自动尝试 128k 免费试听，并限制试听结束时间
- 明确来源的懒加载播放队列、四种播放顺序、跨启动恢复与队列编辑
- 沉浸式全屏播放器、歌词同步、迷你播放器和系统媒体通知
- Drift 本地音乐库读模型（收藏/歌单/历史秒开）与在线写回
- SMS 登录、登录后设备指纹登记与 12 小时前台 token 刷新
- 用户资料、Lite VIP、收藏、最近播放及完整歌单管理
- 收藏、歌单曲目和编辑先更新本地并写回云端（失败回滚）；创建与删除歌单由云端确认
- 登录后即可进入首页，音乐库后台同步，失败可单独重试
- `flutter_secure_storage` 保存 Lite 会话；会话不会写入 Drift，普通日志不记录完整网络数据；
  用户临时启用 Trace 时可记录更详细网络诊断，凭据与敏感设备字段在写盘前脱敏
- Android 明文网络仅允许 `kugou.com` 域及其子域
- Linux 使用 MPRIS，Windows 使用 SMTC；两端支持硬件媒体键
- 桌面窗口关闭后隐藏到系统托盘，托盘菜单可控制播放或彻底退出
- 桌面快捷键：空格播放/暂停，`Ctrl+Left/Right` 上一首/下一首，
  `Ctrl+1/2/3` 切换主导航

## 开发命令

```bash
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
flutter build linux --release
```

Linux 构建环境需要 GTK 3、libsecret、libmpv 和 Ayatana AppIndicator
开发库。DEB 和 AppImage 运行时都需要系统提供 `libmpv.so.2`（Debian/Ubuntu 包名为
`libmpv2`），并提供可用的 Secret Service 凭据服务。生成 DEB 和 AppDir：

```bash
./tool/package_linux.sh 1.0.0
```

Windows release 在 Windows 主机运行 `flutter build windows --release`，MSIX 使用：

```bash
dart run msix:create --build-windows false
```

Windows 使用系统 WinRT `MediaPlayer` 音频后端，不随安装包分发预编译 libmpv/FFmpeg DLL；
可播放编码范围取决于目标 Windows 的 Media Foundation 支持。

普通 PR 和主分支提交会运行 `Checks`：Flutter/Rust 静态检查与测试、许可证校验及 Android Debug 构建。
发布工作流仅在推送 `vMAJOR.MINOR.PATCH`（可选 `+BUILD`）tag 或手动触发时运行。
两种方式都会验证 Flutter/Rust，构建 Android、Linux 与 Windows，并将 APK、AAB、
AppImage、DEB 与 MSIX 上传到对应的 GitHub Release。手动触发时必须填写 release tag；
如果同名 tag 已存在，它必须指向本次选择的 commit，否则工作流会拒绝发布。

Android 正式发布必须配置 `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、
`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。
Windows 正式签名使用 `WINDOWS_PFX_BASE64`、`WINDOWS_PFX_PASSWORD`、
`WINDOWS_PUBLISHER`；缺少任一 Windows 凭据时只生成明确标记的测试签名 MSIX，
并保持 GitHub Release 为 draft。Linux 当前不要求签名证书。

Rust 桥接发生变化后运行：

```bash
flutter_rust_bridge_codegen generate
```

当前 Debug APK 输出到 `build/app/outputs/flutter-apk/app-debug.apk`。

完整文档（架构、开发测试、平台支持、发布、安全和贡献）见
[docs/README.md](docs/README.md)。

## 许可证

Copyright (C) 2026 Zephyrixel and contributors.

KGMusic 自有代码以 [GNU General Public License v3.0 or later](LICENSE) 发布。
`third_party/`、构建工具与分发包中的第三方组件继续适用各自许可证；发布二进制时必须
同时履行相应的版权声明、源码提供和再分发义务。分发说明见 [NOTICE](NOTICE)、
[第三方声明](THIRD_PARTY_NOTICES.md)和自动汇总的
[Rust 依赖许可证](THIRD_PARTY_RUST_NOTICES.txt)。
