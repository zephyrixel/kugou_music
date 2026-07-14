# KGMusic 架构说明

## 边界

项目固定使用 `PlatformProfile::Lite`。Flutter 功能层不直接导入 FRB 自动生成
DTO，而是依赖手写的 `MusicSdk` 接口。这使 SDK 后续新增热门歌单、排行榜详情或
登录 API 时，不需要让生成类型扩散到页面。

```text
features/*
    │
    ├── app/providers.dart (依赖装配)
    │
    ├── core/native/MusicSdk ── FRB generated bindings ── Rust kugou_bridge
    │                                                    └── kugou_sdk 0.2.1 / Lite
    │
    ├── core/player/MusicAudioHandler ── just_audio + audio_service
    │
    └── core/database/AppDatabase ── Drift (收藏、历史)
```

## 目录职责

- `lib/app/`：主题入口、路由和 Riverpod 依赖装配。
- `lib/core/models/`：跨功能使用的稳定领域模型。
- `lib/core/native/`：SDK 门面、生成 DTO 映射、安全会话持久化。
- `lib/core/player/`：播放地址解析、试听降级、队列和系统媒体控制。
- `lib/core/database/`：本地收藏和历史记录；不保存媒体 URL 或会话。
- `lib/core/design_system/`、`widgets/`：深色荧光绿视觉系统与共享组件。
- `lib/features/`：按 home/search/library/player 划分的产品功能。
- `lib/features/auth/`、`account/`、`playlists/`：SMS 登录、账号生命周期与云歌单管理。
- `lib/src/rust/`：FRB 自动生成代码，业务页面不得直接依赖。
- `native/kugou_bridge/`：Rust 异步运行时、Lite SDK 调用和桥接错误映射。

## 播放策略

1. 使用歌曲标准音质 hash 请求完整播放地址。
2. 当 SDK 返回 denied 或 unavailable 时，仅重试一次标准音质免费试听。
3. `just_audio` 播放解析后的临时 URL。
4. SDK 返回 `preview_end_ms` 时，播放器在该位置自动暂停。
5. 只在地址成功装载后写入最近播放记录。

## 会话与安全

Rust 导出的会话外层必须为：

```json
{"schemaVersion":1,"platform":"lite","sessionJson":"..."}
```

导入时拒绝版本不符或 `platform != lite` 的数据。Flutter 使用
`flutter_secure_storage` 保存整个信封；Drift 仅保存可公开的歌曲元数据。

SMS 登录成功后 Rust 会立即注册 `dfid`；注册失败不会撤销有效登录，而是在下次
应用恢复前台时重试。Flutter 在启动、恢复前台及持续前台期间按 12 小时周期刷新
token，`20017/20018` 会清除认证态并要求重新登录。

## 收藏与云歌单

- 游客红心写入本地 `library_tracks`。
- 登录后红心写入 `is_def=2` 的云端「我喜欢」，绝不把 `is_def=1` 默认收藏误认成红心列表。
- 既有本地收藏不会自动批量上传；本地音乐库与账号云音乐保持独立入口。
- Drift schema v2 缓存账号歌单与包含 `file_id` 的歌单歌曲；退出登录清理云缓存但保留本地数据。

## 后续迭代

SDK 尚未稳定或缺失的接口不使用假数据。对应入口保持隐藏，待 Lite API 加入后：

1. 在 Rust `sdk.rs` 增加 DTO 与公开函数。
2. 重新生成 FRB binding。
3. 在 `MusicSdk` 增加稳定领域接口和映射。
4. 最后增加 feature 页面与 capability gate。

建议下一轮优先实现 Lite 登录/二维码、歌词时间轴、排行榜详情、热门歌单与分页搜索。
