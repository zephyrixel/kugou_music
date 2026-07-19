# KGMusic 架构说明

本文是面向维护者的实现约束和数据流说明，不是稳定的第三方 API 文档。高层产品范围见
[项目概览](overview.md)，环境和命令见[开发与测试](development.md)。修改本文描述的
边界时，应同时修改实现与相关测试。

## 边界

项目固定使用 `PlatformProfile::Lite`。Flutter 功能层不直接导入 FRB 自动生成
DTO，而是依赖手写的 `MusicSdk` 接口。这使 SDK 后续新增热门歌单、排行榜详情或
登录 API 时，不需要让生成类型扩散到页面。

```text
features/*
    │
    ├── app/providers.dart (依赖装配)
    ├── core/library/LibraryRepository ── Drift 读模型 + 在线写回
    │       ├── LibraryStore ── Drift CRUD / watch
    │       └── LibraryRemote ── core/native/MusicSdk
    │                              └── FRB ── Rust kugou_bridge
    │                                               └── kugou_sdk 0.2.9 / Lite
    ├── core/cache/MusicRepository ── 推荐、搜索与资料响应缓存
    │
    ├── core/player/MusicAudioHandler ── just_audio + audio_service
    │
    └── core/database/AppDatabase ── Drift (音乐库、推荐画像、响应缓存；无 Outbox)
```

## 启动与依赖装配

`lib/main.dart` 是唯一的组合根。它按以下顺序建立运行时；任一关键步骤失败时显示可读的
启动失败页面，而不是运行半初始化的应用。

```text
Widgets binding
  -> desktop audio runtime
  -> preferences + Flutter logging
  -> Flutter Rust Bridge runtime + native logging
  -> Drift health check
  -> KugouMusicSdk(session restore + device profile)
  -> repositories, cache, queue source factory
  -> AudioService / MusicAudioHandler
  -> desktop lifecycle controller
  -> ProviderScope overrides -> KgMusicApp
```

`app/providers.dart` 只暴露应用所需的依赖和 feature-facing provider。测试通过
`ProviderScope` override 注入替身；页面不创建 SDK、数据库或播放器实例。认证控制器在
恢复到有效账号后激活 `LibraryRepository`，因此路由只有在认证和首轮音乐库同步均完成后
才进入主界面。

## 三条关键数据流

### 登录与账号切换

```text
Android device profile / stable install ID
  -> Rust initialize_sdk
  -> secure-storage session envelope (schema v2, Lite)
  -> AuthController
  -> LibraryRepository.activate(userId)
  -> Drift baseline (playlists + history)
  -> authenticated routes
```

无效、过期或跨设备会话会清除安全存储并回到登录页。退出登录会清除账号响应缓存、音乐库、
推荐画像和播放队列；不会把会话复制到 Drift。

### 浏览、缓存与写回

```text
Feature provider
  -> MusicRepository / LibraryRepository
  -> fresh cache or Drift read model
  -> MusicSdk facade
  -> generated FRB API
  -> Rust kugou_bridge -> kugou_sdk Lite
  -> mapped domain result -> UI stream
```

常规浏览请求使用 `MusicRepository` 的 TTL 缓存和同键请求合并。音乐库不是 JSON 缓存：
`LibraryRepository` 协调 `LibraryStore`（Drift）与 `LibraryRemote`（在线 Lite API）。写操作
遵循“本地乐观更新 -> 在线调用 -> 失败回滚”；新建自建歌单例外，必须先取得远端 `listId`
再写入本地。

### 播放与队列恢复

```text
Song tap
  -> PlaybackQueueSourceFactory (origin + first page)
  -> MusicAudioHandler / PlaybackQueueController
  -> MusicSdk.resolve(song, quality)
  -> LockCachingAudioSource + just_audio
  -> AudioService state -> mini player / full player / system controls
```

队列保存来源、已加载歌曲、索引、顺序和位置。恢复时，`PlaybackQueueSourceFactory.restore`
根据来源重新建立搜索、公开歌单、音乐库或推荐队列的分页加载器；过期的异步地址解析和分页
请求不得覆盖后来选择的歌曲或账号。

## 持久化边界

| 位置 | 内容 | 生命周期 | 明确禁止 |
| --- | --- | --- | --- |
| `flutter_secure_storage` | 会话信封、稳定安装 ID、刷新时间和一次性启动提示 | 登出/会话失效时清理会话 | Drift、日志、普通缓存中的会话/令牌/Cookie |
| Drift `AppDatabase` | 音乐库读模型、推荐画像/限频、非敏感响应缓存、队列快照 | 按账号或缓存策略清理 | token、短信验证码、设备指纹 |
| 文件缓存 | 音频、封面、应用日志 | LRU/用户操作/日志策略 | 以临时签名 URL 作为长期音频身份 |
| SharedPreferences | 音质、缓存上限、窗口几何、日志等级等偏好 | 跨重启保留 | 认证或敏感设备数据 |

数据库 schema 当前为 v7。迁移只能递增；变更表定义、缓存语义或账号清理规则时，必须添加
迁移测试和退出/账号切换测试。

## 目录职责

- `lib/app/`：主题入口、路由和 Riverpod 依赖装配。
- `lib/core/models/`：跨功能稳定领域模型（`Song`、`Playlist`、`HistoryEntry` 等）。
- `lib/core/native/`：SDK 门面、生成 DTO 映射、安全会话持久化。
- `lib/core/library/`：本地读模型、云端 pull/写回、懒加载曲目。
- `lib/core/player/`：播放地址解析、试听降级、队列和系统媒体控制。
- `lib/core/cache/`：接口响应、封面与音频文件缓存；不保存临时播放 URL。
- `lib/core/database/`：本地音乐库与可公开的接口响应；不保存会话。
- `lib/core/design_system/`、`widgets/`：中性深色、封面氛围视觉系统与共享组件。
- `lib/features/`：按 home/search/library/player 划分的产品功能。
- `lib/features/auth/`、`account/`、`playlists/`：SMS 登录、账号生命周期与歌单管理。
- `lib/src/rust/`：FRB 自动生成代码，业务页面不得直接依赖。
- `native/kugou_bridge/`：Rust 异步运行时、Lite SDK 调用和桥接错误映射。

## 设备身份与会话

- Android 启动时通过独立平台通道采集 `ANDROID_ID`、品牌、型号、厂商及免权限的
  内存、存储、电池和传感器信息；无法取得 `ANDROID_ID` 时使用安全存储中的稳定安装 ID。
- Rust 必须收到 `DeviceProfileDto` 后才能初始化运行时，并通过
  `DeviceIdentity::builder` 生成稳定的 `mid/guid/uuid`；生产路径禁止
  `Session::random()`。
- 登录会话使用 schema v2 存入 `flutter_secure_storage`。恢复时必须与当前设备身份
  匹配，并以本次采集的数据刷新设备属性，同时保留 token、cookies、`t1` 和 `dfid`。
- 旧 schema 或跨设备会话通过独立的 `SessionInvalid` 错误清理，其他初始化错误不得
  误删会话；清理后登录页会显示一次明确的重新登录原因。
- 首次短信发码前必须完成 `register_dev`；播放风控重试可强制重新登记。设备指纹
  响应必须实际写入有效 `dfid` 才算成功。后台失败重试限频为 15 分钟，个人中心
  提供显式重试入口。设备指纹和账号登录态均不进入 Drift、日志或普通接口缓存。

## 可维护性约束

- 页面只依赖 `MusicSdk` 的窄接口（如 `BrowseSdk`、`LibrarySdk`、`PlaybackSdk`），
  不直接接触 FRB 类型或 Rust 实现。新增能力先落在对应接口，再接入页面。
- Rust Bridge 按职责拆分为 `api/dto.rs`（跨语言 DTO）、`api/mapping.rs`（SDK 与 DTO
  映射）、`api/error.rs`（统一错误分类）和 `api/sdk.rs`（Lite API 调用）。DTO 仍由
  `sdk` 模块重新导出，以保持生成绑定的公开路径稳定。
- `SongCodec` 是歌曲快照的唯一编解码入口，同时服务响应缓存和播放队列恢复；不要在
  其他缓存或页面中重复实现 JSON 映射。
- `PlaybackQueueController` 只管理队列、索引和顺序；地址解析、音频装载和网络分页
  由播放器协调层负责。`AudioPlayerPort` 用于隔离 just_audio，便于测试和替换。
- `PlaylistTrackLoader` 负责歌单曲目的分页写入、同歌单请求合并和账号切换失效；
  `LibraryRepository` 只协调本地优先写入、云端同步与账号生命周期。
- 保持简单的单向依赖：feature → core → native/database。避免为尚未存在的 Lite API
  添加空壳抽象、全局状态或第二套本地/云端模型。

### 变更落点

| 需求类型 | 首选落点 | 不应直接修改 |
| --- | --- | --- |
| 新 Lite API | Rust `api/sdk.rs`、DTO/映射、`MusicSdk` 窄接口 | feature 中的 FRB 生成类型 |
| 新页面能力 | 对应 `features/`、provider、既有 core 门面 | 在 widget 内创建 SDK 或数据库 |
| 音乐库行为 | `LibraryRepository`、`LibraryStore`、`LibraryRemote` | 页面内重复同步或写回逻辑 |
| 播放行为 | `MusicAudioHandler`、transition、queue controller/source | 直接操纵 `just_audio` 绕过 handler |
| 本地 schema | Drift table、迁移、数据库测试 | 手改 `app_database.g.dart` |

## 播放策略

1. 默认使用标准音质；播放器可按歌曲实际资源切换 320K、FLAC、Hi-Res 或 DSD。
2. Rust 使用与目标音质匹配的 hash，并把 SDK 实际选中的音质和码率返回 Flutter。
3. 当 SDK 返回 denied 或 unavailable 时，仅以同一目标档位重试一次免费试听；试听按标准音质展示。
4. 切换音质会重新解析临时 URL，同时保留播放位置以及播放/暂停状态，不重复写入历史。
5. SDK 返回 `preview_end_ms` 时，播放器在该位置自动暂停。
6. 只在新歌曲地址成功装载后写入最近播放记录。
7. 播放地址使用 `LockCachingAudioSource` 渐进写入可配置的 LRU 缓存（默认 1 GB）；
   缓存键由歌曲 hash、实际音质和试听状态组成，临时签名 URL 不参与资源身份。
8. 进度条仅在用户结束拖动时调用一次 `seek`，避免连续 Range 请求。
9. 切歌先解析地址与准备缓存源，`setAudioSource` 成功后才原子提交歌曲、封面、
   队列索引和音质状态；过期请求不得覆盖新请求。
10. 队列保留每日推荐、搜索或歌单等来源信息，并在接近末尾时按页加载；已缓存
    的搜索/公开歌单页和 Drift 内歌单页优先复用。
11. 支持顺序、列表循环、单曲循环和分批随机；自动续播会跳过明确不可播歌曲，
    网络或认证错误则停止并向 UI 暴露错误。
12. 当前账号的队列、顺序模式和播放位置保存为单条本地响应快照；重启后恢复但
    不自动播放，退出账号时随账号缓存一起清除。
13. Android 通过 `audio_service` 暴露唯一媒体会话；通知栏、锁屏、耳机和蓝牙
    控制器与应用内 UI 共用同一播放状态，暂停时保留会话，显式停止后移除通知。

## 缓存策略

- 推荐、搜索和用户资料使用按类型配置的 TTL：新鲜缓存只读本地，过期缓存先展示
  再后台更新；同一缓存键的并发请求会合并，显式下拉刷新才绕过 TTL。音乐库不使用
  JSON 响应缓存，而是查询结构化本地表。
- 当前 TTL 为：每日推荐 6 小时、资料 30 分钟、会员 10 分钟、搜索 10 分钟、公开
  歌单分页 15 分钟。
- 可重试的网络错误保留旧缓存，认证与业务错误继续上抛。账号缓存按 `user_id`
  隔离，并在退出时清除。
- Drift schema v7：结构化音乐库表（无 Outbox），歌单保存曲目快照数量、完整校验时间和收藏时间；推荐画像与同步限频使用账号隔离的结构化表；通用 JSON 响应缓存最多
  保留 500 项和 30 天。
- 封面、歌单图片和头像使用统一图片缓存，最多 800 项、保留 30 天；Android
  媒体通知优先使用已缓存的本地封面。
- 非敏感应用偏好由统一配置存储维护；默认播放音质和歌曲缓存上限跨重启保留，
  缓存上限可在 256 MB 至 8 GB 间按 256 MB 调整。缩小上限时保护正在播放和下载的文件。
- “清理临时缓存”不会删除登录、音乐库，也不会中断当前播放。

## 会话与安全

Rust 导出的会话外层必须为：

```json
{"schemaVersion":2,"platform":"lite","sessionJson":"..."}
```

导入时拒绝版本不符或 `platform != lite` 的数据。Flutter 使用
`flutter_secure_storage` 保存整个信封；Drift 仅保存可公开的歌曲元数据。

SMS 登录成功后 Rust 会立即注册 `dfid`；注册失败不会撤销有效登录，而是在下次
应用恢复前台时重试。Flutter 在启动、恢复前台及持续前台期间按 12 小时周期刷新
token，`20017/20018` 会清除认证态并要求重新登录。

## 本地音乐库（读模型 + 在线写回）

App 必须登录且播链/搜索依赖网络，因此库层不做持久化 Outbox / 离线编辑队列。

- 应用要求先登录；首次登录以云端歌单、`is_def=2`「我喜欢」和最近播放建立
  本地基线。退出或账号失效会清空本机音乐库。
- **读：** Drift 提供收藏/歌单/历史秒开；普通歌单按页面读取。只有“我喜欢”在登录后按自然日
  后台校验一次完整索引，用于全局红心状态和推荐画像，不阻塞首页。
- **写：** 红心、歌单曲目增删、编辑删除等先乐观更新 Drift，再 `await` 云端；
  失败回滚本地并提示错误。新建自建歌单 **云优先**（先拿到 `listId` 再入库）。
- 播放历史：本地立刻写 `lastPlayedAt`；有 `mixSongId` 时进程内直接
  `uploadHistory`（失败不排队重试）。
- 删除曲目若缺少 `fileId`，仅在删除路径内走 listid 物理序扫描定位；定位失败
  报错，不静默当成功。
- 自动同步有 5 分钟冷却；恢复前台不会无条件拉取。账号页刷新只同步歌单元数据与历史，
  普通歌单曲目按需加载。“我喜欢”首次、数量变化或跨日时低优先级补齐，并使用原子快照替换。
  完整性以远端分页终止为准，实际可用歌曲数可以小于云端声明数量，避免失效歌曲造成无限补拉。
- 元数据同步采用差量合并，保留完整或部分曲目缓存；分页刷新只替换对应页，强制完整刷新成功前
  不删除旧列表。
- 云历史 wire 顺序为旧到新，`bp` 指向更晚记录；同步走到终止游标后再按
  `playedAt` 降序保留最近 100 首。本地新增曲目使用前插 position 显示在顶部。
- 领域类型：`Playlist`（合并原 Cloud/Library 双份）、`HistoryEntry`（合并原
  Cloud/Library 双份）。localId 规则：`remote:{listId}` / `collected:{gid}` /
  `local:{ts}`。

## Personal FM 画像同步

- 所有来源的播放只在本地累计墙钟收听时长；seek 不计时，暂停与音质切换保留会话。
  单次 `>120s` 写 A=3，否则写 A=4；收藏、垃圾桶分别使用 A=1/A=5。
- `report_history` 不是通用播放上报。仅猜你喜欢非登录请求成功返回 `sync_need=1` 且
  `sync_point=0`、完整收藏索引可用、本地画像非空时同步；云播放历史继续走
  `users().history_upload`。
- 每个自然日最多发起 5 次非空同步任务。任务发起时即记录次数与时间，HTTP 失败也不会绕过
  限频；冷却为“本次发起前的当日次数 × 5 分钟 + 0～60 秒随机”，
  状态跨重启保存；冷却命中不会自行定时重试，只等待下一次猜你喜欢拉歌。
- 画像按事件时间降序分为最多 400 条一包（Lite 默认配置），包内反序发送；`prev/next_sync_point`、
  `complete` 与 `last_uplpad_hash`（原切片末项、wire 首项）按官方上传任务游标推进。任一包失败
  即停止并使用通用错误提示。

## 后续迭代

SDK 尚未稳定或缺失的接口不使用假数据。对应入口保持隐藏，待 Lite API 加入后：

1. 在 Rust `sdk.rs` 增加 DTO 与公开函数。
2. 重新生成 FRB binding。
3. 在 `MusicSdk` 增加稳定领域接口和映射。
4. 最后增加 feature 页面与 capability gate。

公开歌单详情、搜索和库内歌单共用分页控制器；库内歌单页面优先查询 Drift，
只在滚动接近末尾时加载缺失曲目页。

## 前端信息架构

- 主导航使用 `StatefulShellRoute.indexedStack`，固定为“发现 / 搜索 / 音乐库”三栏，
  保留各页面的搜索词、分页结果和滚动位置。
- 收藏、最近播放与歌单统一归入音乐库；账号、会员、同步和缓存设置使用独立个人中心，
  不再与音乐库维护重复入口。
- 小屏使用底部导航，大于等于 840dp 使用 `NavigationRail`；播放器继续为独立全屏页面，
  歌单详情使用可折叠封面头部和吸顶播放栏。
- 视觉系统使用中性深色表面与蓝紫语义强调色，封面通过现有图片缓存生成模糊氛围背景，
  不引入运行时调色依赖。所有动效必须尊重系统“减少动态效果”设置。

建议下一轮优先实现 Lite 登录/二维码、歌词时间轴、排行榜详情与热门歌单。
