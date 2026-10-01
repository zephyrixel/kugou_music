# 项目概览

KGMusic 是一个 Android、Linux 和 Windows 音乐客户端。Flutter 负责界面、状态与本地
体验，Rust 通过 Flutter Rust Bridge 调用 `kugou_sdk`，并固定使用 Lite 平台配置。
它不是酷狗官方客户端，也不提供 Standard 后端兼容层。

## 面向的使用场景

应用面向已经具备 Lite 账号的用户：登录后浏览每日推荐、搜索歌曲与歌单、维护个人
音乐库，并在移动设备或桌面环境播放音乐。网络请求和播放地址解析依赖 Lite 服务；
应用不承诺离线搜索或离线播放服务。

## 已实现能力

- 短信登录、设备登记、前台 12 小时 token 刷新，以及失效会话的安全清理。
- 每日推荐、Discovery 卡片、猜你喜欢/红心电台、歌曲和歌单搜索。
- 云端歌单、收藏和最近播放的本地读模型；写操作先更新本地，再同步 Lite 服务，失败时
  回滚。
- 标准、320K、FLAC、Hi-Res、DSD 音质选择；无法完整播放时可降级为受限免费试听。
- 懒加载播放队列、顺序/列表循环/单曲循环/随机模式、歌词、迷你播放器和跨启动恢复。
- 音频、封面、歌词和接口响应缓存，以及可配置的音频缓存上限。
- Android 媒体通知与耳机/蓝牙控制；Linux MPRIS、Windows SMTC、系统托盘和桌面快捷键。

## 支持边界

| 目标 | 状态 | 说明 |
| --- | --- | --- |
| Android | 支持 | 主要移动端目标；正式包为 APK 与 AAB。 |
| Linux x86_64 | 支持 | 提供 DEB 和 AppImage；使用 GTK 3 与 MPRIS。 |
| Windows x64 | 支持 | 提供 MSIX；使用 SMTC。 |
| iOS、macOS、Web | 未提供发布支持 | 不应将其视为已验证的运行目标。 |

Linux 与 Windows 的细节见[平台支持](platforms.md)。构建和本地运行见
[开发与测试](development.md)。

## 设计原则

- **Lite-only：** Rust 运行时始终构造 `PlatformProfile::Lite`，不引入 Standard
  fallback。
- **领域边界：** 页面依赖手写 `MusicSdk` 接口和领域模型，而不依赖 FRB 生成 DTO。
- **本地优先读取，在线确认写入：** Drift 用于公开音乐元数据和缓存，不是会话或离线
  Outbox。
- **敏感信息最小化：** 会话仅进入安全存储；令牌、Cookie、设备指纹不进入 Drift 或普通
  缓存。普通日志只保留最小化/脱敏摘要；用户临时启用 Trace 时网络跟踪也会脱敏敏感字段，
  并会在重启后回落到 Debug。

更完整的数据流、缓存策略和并发约束见[架构](architecture.md)。
