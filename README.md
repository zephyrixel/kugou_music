# KGMusic

KGMusic 是一个 Android-first 的 Flutter 音乐客户端，使用 Rust
`kugou_sdk = 0.2.1` 访问酷狗 Lite（概念版）接口。项目不会回退到 Standard
后端。

## 当前首轮能力

- Lite 每日推荐与歌曲搜索
- Rust 侧播放地址解析，Flutter `just_audio` 负责实际播放
- 完整播放失败时自动尝试 128k 免费试听，并限制试听结束时间
- 播放队列、迷你播放器、全屏播放器和系统媒体通知
- Drift 本地收藏与最近播放记录
- SMS 登录、登录后设备指纹登记与 12 小时前台 token 刷新
- 用户资料、Lite VIP、云历史及完整云歌单管理
- 游客使用本地收藏；登录后红心同步到云端“我喜欢”
- `flutter_secure_storage` 保存 Lite 会话；会话不会写入 Drift 或日志
- Android 明文网络仅允许 `kugou.com` 域及其子域

## 开发命令

```bash
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
```

Rust 桥接发生变化后运行：

```bash
flutter_rust_bridge_codegen generate
```

当前 Debug APK 输出到 `build/app/outputs/flutter-apk/app-debug.apk`。

详细的分层结构和后续路线见 [docs/architecture.md](docs/architecture.md)。
