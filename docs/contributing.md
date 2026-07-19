# 贡献指南

感谢对 KGMusic 的改进。贡献应保持 Lite-only 边界、保护用户会话，并尽量让每个提交只
解决一个可验证的问题。

## 开始前

先阅读[项目概览](overview.md)、[架构](architecture.md)和
[开发与测试](development.md)。提交功能建议先说明用户价值、涉及的平台、网络/数据变更和
测试方案。不要为 SDK 尚不稳定或不存在的 Lite API 添加假数据、空页面或 Standard fallback。

仓库以 [GNU General Public License v3.0 or later](../LICENSE) 发布。提交贡献即表示你有权
提供相关内容，并同意该贡献按 `GPL-3.0-or-later` 与项目一同分发。`third_party/` 中的代码
继续适用其原始许可证；修改这些目录时必须保留版权与许可证声明。

## 代码边界

- 页面与 feature 代码依赖 `MusicSdk` 的窄接口和领域模型；不要直接导入 FRB 生成 DTO。
- Flutter 保持 `feature -> core -> native/database` 的单向依赖。可复用行为放进 `core/`，
  页面特有 UI 留在对应 `features/` 目录。
- Rust Bridge 按 DTO、映射、错误分类和 SDK 调用分层。改变公开 Bridge API 时，同时更新
  手写 Dart 门面、生成绑定和相关测试。
- `PlatformProfile::Lite` 是不可变约束；不得增加 Standard 回退路径。
- 会话只能进入 `flutter_secure_storage`，不能写入 Drift 或日志。

## 编码与提交

使用两空格 Dart 缩进、`lower_snake_case.dart` 文件名、`UpperCamelCase` 类型和
`lowerCamelCase` 成员。提交前运行：

```bash
dart format .
flutter analyze
flutter test
cargo fmt --all --check
cargo test --manifest-path native/kugou_bridge/Cargo.toml
```

如果修改 Drift、Freezed 或 Flutter Rust Bridge，按[开发与测试](development.md)重新生成
代码并提交必要的生成文件。不要手工修改生成文件，也不要在同一提交混入无关格式化、
锁文件升级或第三方目录修改。

提交信息使用简短、结果导向的主题，例如 `feat: add playlist paging` 或
`修复：恢复桌面窗口位置`。一个 PR 应说明行为变化、测试命令、平台影响，并为 UI 变化
提供截图或录屏。涉及 schema、生成绑定、SDK 版本、签名或安全边界时必须明确标注。

## 测试期待

为行为变更添加聚焦回归测试，尤其是：

- 登录、会话失效、设备登记和敏感数据处理；
- 分页、缓存 TTL、账号切换和音乐库同步；
- 播放队列、音质切换、试听降级与系统媒体状态；
- 数据库迁移、乐观写入与失败回滚；
- Linux/Windows 的平台分支和窗口状态纯逻辑。

无法在本地覆盖的平台构建应在 PR 中如实说明，由 CI 或对应平台维护者验证。不要用跳过
测试代替解释已知限制。

## 提交前清单

- [ ] 变更有清晰的用户、维护或安全价值，并且没有扩大到未请求的重构。
- [ ] 保持 Lite-only、会话安全存储和 feature → core → native/database 的依赖方向。
- [ ] 新行为具有聚焦测试；修改生成输入后已重新生成相应文件。
- [ ] 已运行与变更范围相符的检查，并在 PR 中列出实际执行的命令。
- [ ] UI、数据库、Bridge、SDK、平台或签名变更已在 PR 描述中明确标注。
- [ ] 不包含密钥、真实会话、个人资料、未脱敏日志、构建产物或无关格式化。
