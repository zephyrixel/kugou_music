# 开发与测试

本文面向需要运行、修改或验证 KGMusic 的开发者。所有命令均在仓库根目录执行。

## 工具链

CI 使用 Flutter `3.44.1`、稳定版 Rust 和 Java 17。为了减少本地与 CI 差异，建议使用
相同 Flutter 版本，并让 `rustc --version` 满足
[`native/kugou_bridge/Cargo.toml`](../native/kugou_bridge/Cargo.toml) 声明的最低版本。

还需要：

- Android：Android SDK、NDK 和 Java 17；使用真机或模拟器时执行 `flutter devices` 确认。
- Linux：GTK 3、libsecret、libmpv、Ayatana AppIndicator，以及 CMake/Ninja 工具链。
- Windows：Visual Studio 的“Desktop development with C++”、Windows SDK、MSVC Rust
  toolchain。MSIX 只能在 Windows 主机创建。

Ubuntu/Debian 上安装 Linux 构建依赖：

```bash
sudo apt-get update
sudo apt-get install -y \
  appstream clang cmake desktop-file-utils libayatana-appindicator3-dev \
  libgtk-3-dev libmpv-dev libsecret-1-dev ninja-build pkg-config
```

运行 Linux 桌面版还需要可用的 Secret Service 凭据服务。详细的运行时依赖和各平台
行为见[平台支持](platforms.md)。

## 首次准备与运行

```bash
flutter pub get
flutter run
```

`flutter run` 会根据已连接设备选择目标；指定平台时使用 Flutter 标准的设备 ID 或
`-d linux`、`-d windows`。首次 Android 构建会下载所需的 Gradle/NDK 组件。

## 日常工作流

1. 在修改前定位职责边界：页面在 `lib/features/`，可复用业务在 `lib/core/`，SDK 调用
   经 `lib/core/native/music_sdk.dart`，Bridge 实现在 `native/kugou_bridge/`。
2. 先为行为写或调整聚焦测试，再修改实现。测试文件与实现职责同名，位于 `test/`。
3. 在 Dart 与 Rust 两侧分别完成静态检查、单元测试和必要的生成代码更新。
4. 通过目标平台完成冒烟验证；涉及登录、播放器、托盘或媒体键时，纯单元测试不能替代。

不要为方便调试将会话、令牌、设备 ID 或真实网络响应写入 fixture、日志或提交信息。

## 验证命令

提交前至少运行与变更范围匹配的检查：

```bash
flutter analyze
flutter test
cargo test --manifest-path native/kugou_bridge/Cargo.toml
```

构建命令：

```bash
flutter build apk --debug
flutter build linux --release
flutter build windows --release
```

Android、Linux 和 Windows 的正式可分发包由 CI 构建；本地发布打包流程见
[发布](releasing.md)。

### 按变更类型选择验证

| 变更 | 最低验证 | 额外关注 |
| --- | --- | --- |
| Widget、路由、状态 | `flutter analyze`、相关 `flutter test` | 小屏/桌面布局与登录重定向 |
| 播放、队列、缓存 | 相关 Dart 测试 | 真实设备播放、媒体通知或桌面媒体键 |
| Drift 表/迁移 | `flutter test` | 新旧 schema 迁移、账号切换和缓存清理 |
| Rust Bridge/SDK 映射 | `cargo fmt --all --check`、`cargo test`、Dart 测试 | 重新生成 FRB 绑定和错误映射 |
| Linux/Windows 集成 | `flutter build linux/windows --release` | 系统依赖、托盘、MPRIS/SMTC |
| Android 签名/发布 | CI release workflow | 不使用 debug 签名、APK/AAB 校验 |

## 生成代码

以下文件由工具生成，禁止直接编辑：

- Drift：`lib/core/database/app_database.g.dart`
- Freezed：对应模型的 `*.freezed.dart`
- Flutter Rust Bridge：`lib/src/rust/` 与 Rust 侧生成绑定

修改 Drift 表、Freezed 注解后运行：

```bash
dart run build_runner build
```

修改 Rust Bridge 的公开 API、DTO 或 `flutter_rust_bridge.yaml` 后运行：

```bash
flutter_rust_bridge_codegen generate
```

生成后检查 diff，只提交由本次源代码变更产生的文件。不要以格式化或代码生成的副作用
混入无关改动。

## 日志与本地数据

应用日志位于应用支持目录的 `logs` 子目录；设置页可查看、导出和清理日志。日志用于
诊断，不应记录 token、Cookie、短信验证码或设备指纹。开发中需要重置登录状态时，使用
应用内退出登录或系统设置清除应用数据，避免手工复制安全存储内容。

Drift 数据库保存音乐库读模型、推荐画像与非敏感响应缓存。音频缓存位于临时目录，可在
应用设置中清理，不会删除登录状态或音乐库。

## 排障顺序

| 症状 | 优先检查 | 常见根因 |
| --- | --- | --- |
| 启动失败 | 启动失败页与应用日志 | Flutter Rust Bridge 初始化、数据库、音频或安全存储不可用 |
| 登录循环或自动退出 | `AuthController` 流程与安全存储 | 会话 schema/设备身份不匹配、token 失效 |
| 页面数据不刷新 | repository 缓存策略与 provider | TTL 命中、账号未激活、请求合并或网络错误 |
| 歌曲无法播放 | `MusicAudioHandler` 日志和解析结果 | 资源权限、临时 URL、网络、试听限制 |
| Linux/Windows 无媒体控制 | 平台依赖和插件注册时机 | MPRIS/SMTC 后端未在创建播放器前初始化 |

导出日志只用于最小化复现。报告问题时附上应用版本、平台、复现步骤和脱敏错误信息，不附
会话或签名材料。
