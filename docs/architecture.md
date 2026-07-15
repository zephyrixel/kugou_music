# KGMusic 架构说明

## 边界

项目固定使用 `PlatformProfile::Lite`。Flutter 功能层不直接导入 FRB 自动生成
DTO，而是依赖手写的 `MusicSdk` 接口。这使 SDK 后续新增热门歌单、排行榜详情或
登录 API 时，不需要让生成类型扩散到页面。

```text
features/*
    │
    ├── app/providers.dart (依赖装配)
    ├── core/library/LibraryRepository ── Drift 音乐库 + Outbox
    │       └── LibrarySyncService ── core/native/MusicSdk
    │                                  └── FRB ── Rust kugou_bridge
    │                                                   └── kugou_sdk 0.2.2 / Lite
    ├── core/cache/MusicRepository ── 推荐、搜索与资料响应缓存
    │
    ├── core/player/MusicAudioHandler ── just_audio + audio_service
    │
    └── core/database/AppDatabase ── Drift (音乐库、同步状态、响应缓存)
```

## 目录职责

- `lib/app/`：主题入口、路由和 Riverpod 依赖装配。
- `lib/core/models/`：跨功能使用的稳定领域模型。
- `lib/core/native/`：SDK 门面、生成 DTO 映射、安全会话持久化。
- `lib/core/library/`：本地音乐库事务、Outbox、云快照合并和后台同步。
- `lib/core/player/`：播放地址解析、试听降级、队列和系统媒体控制。
- `lib/core/cache/`：接口响应、封面与音频文件缓存；不保存临时播放 URL。
- `lib/core/database/`：本地音乐库、待同步操作和可公开的接口响应；不保存会话。
- `lib/core/design_system/`、`widgets/`：深色荧光绿视觉系统与共享组件。
- `lib/features/`：按 home/search/library/player 划分的产品功能。
- `lib/features/auth/`、`account/`、`playlists/`：SMS 登录、账号生命周期与歌单管理。
- `lib/src/rust/`：FRB 自动生成代码，业务页面不得直接依赖。
- `native/kugou_bridge/`：Rust 异步运行时、Lite SDK 调用和桥接错误映射。

## 播放策略

1. 默认使用标准音质；播放器可按歌曲实际资源切换 320K、FLAC、Hi-Res 或 DSD。
2. Rust 使用与目标音质匹配的 hash，并把 SDK 实际选中的音质和码率返回 Flutter。
3. 当 SDK 返回 denied 或 unavailable 时，仅以同一目标档位重试一次免费试听；试听按标准音质展示。
4. 切换音质会重新解析临时 URL，同时保留播放位置以及播放/暂停状态，不重复写入历史。
5. SDK 返回 `preview_end_ms` 时，播放器在该位置自动暂停。
6. 只在新歌曲地址成功装载后写入最近播放记录。
7. 播放地址使用 `LockCachingAudioSource` 渐进写入 1 GB LRU 缓存；缓存键由歌曲
   hash、实际音质和试听状态组成，临时签名 URL 不参与资源身份。
8. 进度条仅在用户结束拖动时调用一次 `seek`，避免连续 Range 请求。

## 缓存策略

- 推荐、搜索和用户资料先返回 Drift 响应缓存，再向 Lite 后端更新；同一缓存键
  的并发请求会合并。音乐库不使用 JSON 响应缓存，而是查询结构化本地表。
- 可重试的网络错误保留旧缓存，认证与业务错误继续上抛。账号缓存按 `user_id`
  隔离，并在退出时清除。
- Drift schema v4 使用结构化音乐库表和持久化 Outbox；通用 JSON 响应缓存最多
  保留 500 项和 30 天。
- 封面、歌单图片和头像使用统一图片缓存，最多 800 项、保留 30 天；Android
  媒体通知优先使用已缓存的本地封面。
- “清理临时缓存”不会删除登录、音乐库或待同步操作，也不会中断当前播放。

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

## 本地优先音乐库

- 应用要求先登录；首次登录以云端歌单、`is_def=2`「我喜欢」和最近播放建立
  本地基线。退出或账号失效会清空本机音乐库与待同步操作。
- 红心、播放历史、歌单创建/编辑/删除、收藏歌单及歌曲增删都先在 Drift 事务中
  生效，再写入按实体去重的 Outbox。
- `LibrarySyncService` 串行推送操作，歌单创建先于成员写入；失败采用退避重试，
  不回滚本地状态。云端刷新不会覆盖仍有待同步意图的本地实体。
- 歌单展示有 gid 时使用官方新到旧顺序；删除若缺少 `fileId`，仅为定位删除参数
  走 listid 物理序扫描。定位失败必须保留 Outbox，不能把未执行的删除视为成功。
- 账号页刷新只同步歌单元数据，不预取任何歌单曲目；曲目在进入具体歌单或收藏
  歌曲页时一次性懒加载，之后直接读取 Drift，除非用户在歌单页主动下拉刷新。
- 云历史 wire 顺序为旧到新，`bp` 指向更晚记录；同步必须走到终止游标后再按
  `playedAt` 降序保留最近 100 首。本地新增歌曲使用前插 position 立即显示在顶部。
- 0.2.2 的 Lite `history_upload` 使用 `mixSongId`、秒级播放时间和累计次数批量上报；
  缺少 `mixSongId` 的记录仅保留本地。

## 后续迭代

SDK 尚未稳定或缺失的接口不使用假数据。对应入口保持隐藏，待 Lite API 加入后：

1. 在 Rust `sdk.rs` 增加 DTO 与公开函数。
2. 重新生成 FRB binding。
3. 在 `MusicSdk` 增加稳定领域接口和映射。
4. 最后增加 feature 页面与 capability gate。

建议下一轮优先实现 Lite 登录/二维码、歌词时间轴、排行榜详情、热门歌单与分页搜索。
