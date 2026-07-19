# KGMusic 文档中心

KGMusic 是使用 Flutter 与 Rust 构建的酷狗 Lite 音乐客户端。此目录服务于三类读者：
使用者了解应用边界与日常使用方式，开发者理解实现与验证方法，维护者完成安全发布。
所有结论均以当前仓库代码、锁定依赖和 CI 配置为准。

> KGMusic 不是酷狗官方客户端。应用只使用 Lite 平台配置，不提供 Standard 后端回退。

## 从这里开始

| 你的目标 | 阅读顺序 |
| --- | --- |
| 安装、登录并使用应用 | [项目概览](overview.md) → [使用指南](user-guide.md) → [平台支持](platforms.md) |
| 在本地运行、调试或测试 | [开发与测试](development.md) → [架构](architecture.md) |
| 修改业务、数据或 Rust Bridge | [架构](architecture.md) → [开发与测试](development.md) → [贡献指南](contributing.md) |
| 构建并发布版本 | [发布指南](releasing.md) → [安全与隐私](security.md) |
| 评估数据与安全边界 | [安全与隐私](security.md) → [架构](architecture.md) |

## 文档地图

| 文档 | 维护内容 | 主要读者 |
| --- | --- | --- |
| [项目概览](overview.md) | 产品范围、已实现能力、非目标 | 使用者、评估者 |
| [使用指南](user-guide.md) | 登录、播放、音乐库、桌面交互与常见问题 | 使用者 |
| [架构](architecture.md) | 模块职责、启动/数据流、持久化、并发不变量 | 开发者 |
| [开发与测试](development.md) | 工具链、日常工作流、代码生成、测试与调试 | 开发者 |
| [平台支持](platforms.md) | Android、Linux、Windows 的能力与依赖 | 使用者、打包者 |
| [发布指南](releasing.md) | tag、版本、CI、签名、验证与回滚 | 维护者 |
| [安全与隐私](security.md) | 数据分级、密钥、日志与漏洞处置 | 所有人 |
| [贡献指南](contributing.md) | 变更边界、提交、评审和测试标准 | 贡献者 |
| [许可证与第三方声明](../THIRD_PARTY_NOTICES.md) | 版权、组件许可证与对应源码 | 使用者、打包者 |

## 维护规则

- 产品或平台行为改变时，同时更新对应用户文档。
- 修改启动链路、存储模型、SDK 门面、播放队列或安全边界时，更新 `architecture.md`。
- 修改 CI、签名、版本规则或产物名称时，更新 `releasing.md`。
- 命令默认从仓库根目录执行；文档中的秘密名称可以公开，秘密值绝不能进入仓库、日志或截图。
- 生成文件只由其工具更新：Drift 的 `*.g.dart`、Freezed 的 `*.freezed.dart` 和
  `lib/src/rust/` 都不手工编辑。
