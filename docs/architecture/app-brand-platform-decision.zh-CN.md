# App 品牌与平台决策

## 推荐工作名称

### `StrideMetric`

商店副标题建议：

- English: `StrideMetric: Shoe Size Converter`
- 简体中文：`StrideMetric 鞋码换算`

选择理由：

- `Stride` 表达步伐与穿鞋场景，`Metric` 表达测量和换算。
- 英语用户能理解，中文、日文、韩文市场也容易读。
- 不把产品限制在某一个国家尺码。
- 后续可以扩展品牌鞋码、家庭档案和试穿记录。

正式上架前必须再完成：

- Apple App Store、Google Play 的同名与近似名检索。
- 主要商标数据库的检索。
- 域名和社交账号可用性检查。

当前代码使用工作包名：

`com.stridemetric.shoe`

首次提交商店后应用 ID 不宜再更改，因此在第一次签名发布前必须由发布者最终确认。

## Logo 方向

图形元素：

- 深海军蓝圆角底。
- 青绿色脚印。
- 一条简洁的测量刻度线。
- 不在图标中放文字或国家旗帜。

要求：

- 1024×1024 原始图。
- 小到 48×48 仍能识别。
- Android adaptive icon 前景与背景分层。
- iOS 图标不预先切圆角。
- 单色通知图标另行输出。

## 技术平台

### 首选 Flutter

理由：

- Android 与 iOS 共用 UI 和业务逻辑。
- 现有换算引擎是纯 Dart，可直接复用。
- 离线 JSON/SQLite、列表、表格和本地档案适合 Flutter。
- 后续可以通过平台通道接入广告、内购、隐私同意和商店评分。

### Android

- 当前主要开发与真机验证平台。
- 使用 Android Studio 打开 `apps/sole_metric/android` 或 Flutter 根项目。
- 正式发布使用 App Bundle `AAB`。

### iOS

- Windows 可以维护 Flutter 与 iOS 工程文件，但最终签名、真机测试和上传必须使用 macOS + Xcode。

### HarmonyOS

- 不把 HarmonyOS 作为首版阻塞项。
- 保持 domain、catalog 和 storage 与 Flutter UI 解耦。
- 等 Android/iOS 版本稳定后，再根据当时的 Flutter HarmonyOS 生态或 ArkUI 原生方案评估。

## 广告与商业化

首版仅预留底部横幅广告接口，不立即把具体广告 SDK 写进核心业务。

接入原则：

- 广告服务通过抽象接口注入。
- 隐私同意完成前不加载个性化广告。
- 不把脚长、鞋码、姓名、头像传给广告 SDK。
- 提供一次性买断去广告的技术扩展位。
- 激励广告不得影响免费换算的准确性和完整性。
