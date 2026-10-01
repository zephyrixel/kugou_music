# 发布指南

本文面向拥有仓库发布权限的维护者。GitHub Actions 工作流位于
`.github/workflows/desktop.yml`，只在推送 `v*` tag 或手动触发时执行。

## 版本与触发

接受的发布 tag 为：

```text
vMAJOR.MINOR.PATCH
vMAJOR.MINOR.PATCH+BUILD
```

其中四个 Windows 版本组件都必须不大于 `65535`，且 `BUILD` 必须为正整数。未显式提供
`+BUILD` 时，CI 使用 GitHub Actions 的运行编号作为 Android `versionCode` 和 MSIX 的
第四个版本组件。

推荐的正式发布方式是在已经验证的提交上创建并推送 tag：

```bash
git tag v1.2.3+4
git push origin v1.2.3+4
```

手动触发 `Release` 工作流时必须填写 `release_tag`。工作流使用所选提交构建；若同名 tag
已经存在，必须解析到该提交，否则失败。不存在的 tag 由发布 action 在创建 Release 时指向
所选提交。

## CI 阶段与产物

1. `checks`：复用日常 Flutter/Rust 检查、测试、许可证校验和 Android Debug 构建；`validation` 在检查通过后解析发布版本。
2. `prepare_release`：创建缺失的 draft Release，或复用已有 draft；已公开的同 tag Release
   会被拒绝重跑，避免替换公开附件。
3. `android`：构建并校验签名的 universal、`armeabi-v7a`、`arm64-v8a` APK，以及 AAB。
4. `linux`：构建 bundle，校验 desktop/AppStream 元数据，生成 DEB、AppImage。
5. `windows`：使用 WinRT 音频后端构建 x64 bundle，创建已签名或测试签名的 MSIX。
6. 三个平台 job 各自将验证后的文件直接上传到该 Release，不使用 GitHub Actions artifact
   存储。
7. `finalize_release`：Windows 正式签名时公开 draft；测试签名时保留 draft。

Release 附件包括三个 Android APK（universal、`armeabi-v7a`、`arm64-v8a`）、AAB、DEB、
AppImage 和 MSIX。直接上传避免 Actions artifact 存储配额阻断发布；若任一平台构建失败，
draft Release 可能保留已上传的部分附件，但不会自动公开。准备、上传和最终发布 job 仅获得
所需的 `contents: write` 权限。平台 job 需要写权限是因为产物直接上传 draft Release；
checkout 禁止持久化凭据，写 token 只显式传给上传步骤。所有外部 Action 固定到完整 commit
SHA，由 Dependabot 提议升级；公开下载 linuxdeploy 时不发送仓库 token。

## 发布前检查表

- [ ] 工作区干净，目标提交已合并且相关 Dart/Rust 测试通过。
- [ ] `pubspec.yaml`、tag 和用户可见版本说明一致。
- [ ] Android 四项签名 secrets 可用，密钥 alias 可被读取。
- [ ] 如需公开 Windows 安装包，PFX、密码和精确 Publisher 已配置且证书未过期。
- [ ] 已确认没有将 session、token、PFX、keystore 或 Base64 秘密写入提交、Release 文本或
  issue。
- [ ] 未附带未脱敏的 Trace 日志；排障完成后已切回较低等级并清空本机 Trace 记录。
- [ ] `NOTICE`、`THIRD_PARTY_NOTICES.md`、`THIRD_PARTY_RUST_NOTICES.txt` 与依赖锁文件
  一致，且安装包包含这些声明。
- [ ] Linux 目标环境可提供 `libmpv.so.2`；Windows bundle 不包含 `libmpv-2.dll` 或其他
  来源不明的 FFmpeg 构件。
- [ ] GitHub 自动生成的 source archive 指向同一 release tag，可作为该版本 KGMusic 源码入口。
- [ ] 已准备本版本的变更说明和目标平台的冒烟测试环境。

## 必需的 Android 密钥

每次发布都必须配置以下 GitHub Actions secrets：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | upload keystore 的 Base64 编码，不含文件路径 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 签名 key alias |
| `ANDROID_KEY_PASSWORD` | 签名 key 密码 |

构建前 CI 会解码密钥、检查 alias，并在完成后删除临时 keystore。缺少任一项会失败；
绝不会回退为 debug key 签名。开发者本地可在 `android/key.properties` 中配置
`storeFile`、`storePassword`、`keyAlias`、`keyPassword`；该文件与实际 keystore 都不得提交。
CI 使用 `apksigner` 校验 APK，使用 `jarsigner` 校验 AAB 的 JAR 签名和已签名状态。Android
upload certificate 通常是自签名证书，因此 AAB 校验不要求其证书链连接到公有 CA；证书指纹
和持续使用同一 upload key 的责任仍由发布维护者承担。

## Windows 签名

下面三个 secrets 同时存在时，CI 用 PFX 创建正式签名 MSIX：

| Secret | 内容 |
| --- | --- |
| `WINDOWS_PFX_BASE64` | 带私钥的 PFX Base64 编码 |
| `WINDOWS_PFX_PASSWORD` | PFX 密码 |
| `WINDOWS_PUBLISHER` | 与 PFX Subject 完全一致的 Publisher 字符串 |

CI 会校验证书私钥、Subject 和有效期。缺少任何 Windows 签名 secret 时，CI 创建名称含
`TEST-SIGNED` 的测试签名 MSIX，并把 GitHub Release 保持为 draft，供维护者复核后处理。
Linux 当前不要求签名证书。

## 发布后的检查

- 确认 Release tag、提交和版本号一致。
- 下载每个平台产物并至少完成一次安装/启动冒烟测试。
- 检查 Android 安装包签名、Windows 证书信任状态和 Linux DEB 元数据。
- 抽查每个平台产物中的 GPL、第三方和 Rust 许可证声明。
- 若 Windows 为测试签名，先完成正式签名和安装验证，再将 draft Release 公开。
- 不在 issue、日志、Release 描述或附件中放置证书、密码、token 或 Base64 密钥材料。

## 失败处理与重发

构建失败时先修复根因并重新运行同一 tag 的工作流；不要为了绕过签名、版本或校验失败而
手工上传未验证产物。若 tag 已经指向错误提交，应停止发布、创建指向正确提交的新版本 tag，
并在 Release 说明中记录替代关系。已公开的错误构件应撤下或标为不可使用，同时评估是否
需要轮换泄露的签名材料。
