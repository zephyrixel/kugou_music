# KGMusic

KGMusic 是一个支持 Android、Linux 与 Windows 的 Flutter 音乐客户端，使用 Rust
`kugou_sdk = 0.2.9` 访问酷狗 Lite（概念版）接口。项目不会回退到 Standard
后端。

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
- 收藏、播放历史和歌单操作乐观写入本地并立即回写 Lite 云端（失败回滚）
- `flutter_secure_storage` 保存 Lite 会话；会话不会写入 Drift 或日志
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
开发库。运行时需要可用的 Secret Service 凭据服务。生成 DEB 和 AppDir：

```bash
./tool/package_linux.sh 1.0.0
```

Windows release 在 Windows 主机运行 `flutter build windows --release`，MSIX 使用：

```bash
dart run msix:create --build-windows false
```

GitHub Actions 只在推送 `vMAJOR.MINOR.PATCH`（可选 `+BUILD`）tag 或手动触发时运行。
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

详细的分层结构和后续路线见 [docs/architecture.md](docs/architecture.md)。
