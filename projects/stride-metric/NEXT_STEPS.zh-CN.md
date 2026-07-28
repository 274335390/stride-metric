# StrideMetric 下一阶段开发接手清单

> 更新日期：2026-07-27
> GitHub：<https://github.com/274335390/dd-openSource>
> 基线提交：`5b1569ce945039adcaacc3abd436f2226487ecd4`
> 当前范围：离线国际鞋码换算，Android / iOS；服装尺码不进入首版

## 1. 新任务必须使用的目录

正式仓库：

```text
C:\Users\27433\Documents\dd-openSource
```

StrideMetric 项目：

```text
C:\Users\27433\Documents\dd-openSource\projects\stride-metric
```

Flutter 工程：

```text
C:\Users\27433\Documents\dd-openSource\projects\stride-metric\apps\stride_metric
```

不要继续在以下目录开发：

```text
C:\Users\27433\Documents\炫酷前端
C:\tmp\dd-openSource-publish
```

“炫酷前端”是前期工作目录，`C:\tmp` 是一次性发布目录；后续唯一可信工作区是正式克隆的 `dd-openSource`。

## 2. 新任务开始时先阅读

按顺序阅读：

1. `projects/stride-metric/README.md`
2. `projects/stride-metric/DATA_NOTICE.md`
3. `projects/stride-metric/docs/architecture/flutter-screen-logic-v1.zh-CN.md`
4. `projects/stride-metric/docs/architecture/system-architecture.zh-CN.md`
5. `projects/stride-metric/docs/architecture/internationalization-v1.zh-CN.md`
6. `projects/stride-metric/docs/data-coverage-audit-2026-07-26.zh-CN.md`

其中 `flutter-screen-logic-v1.zh-CN.md` 是页面、弹层、导航、单位显示和产品文案的当前基准。若 HTML 原型与该文档冲突，以该文档和最新 Flutter 实现为起点，再通过真机体验修正。

## 3. 当前已经完成

- 已建立 Flutter Android / iOS 工程。
- 已建立纯 Dart `size_domain` 包。
- 已接入成人、童鞋标准数据和多品牌官方尺码表。
- 已有男款、女款、童款三个入口。
- 已有“脚长”和“现有尺码”两种换算方式。
- 已有 mm、cm、in 三种全局长度单位。
- 已有标准表、品牌表、档案和设置页面。
- 已有浅色/深色主题。
- 已有本地档案保存和设置持久化。
- 已建立 13 种界面语言的文案表和完整性测试：
  `en`、`tr`、`de`、`es`、`fr`、`it`、`pt-BR`、`ja`、`ko`、`zh-CN`、`ru`、`nl`、`hi`。
- 已有数据来源登记、JSON 数据校验和基础 Flutter 测试。
- 当前基线验证结果：
  - `flutter analyze`：0 个问题。
  - `flutter test`：14 项通过。
  - `node scripts/validate-data.mjs`：`ok: true`。

这些结果表示工程可继续开发，不表示已经达到商店发布质量。

## 4. 当前必须优先解决的逻辑风险

### 4.1 换算不能简单取“最近一行”

当前 `ShoeCatalog.nearest()` 使用绝对距离选择最近行。正式版本需要根据标准表的适用区间、有效鞋长范围和品牌官方规则匹配：

- 命中明确区间时返回对应行。
- 位于相邻离散值之间时，按标准或品牌规则给出结果。
- 超出范围时返回 `unsupported/outOfRange`，禁止线性外推。
- 不得为了让页面有值而静默返回最接近的边界尺码。

### 4.2 已知尺码不能静默回退到默认脚长

当前 `byKnownSize()` 会选择数值最接近的行；找不到时，`convert()` 还可能回退到当前 `footMm`。这会制造看似合理但来源错误的结果。

需要改成：

- 先精确匹配当前受众、尺码体系和合法标签。
- 对品牌分数码、童鞋编号重置使用字符串或结构化标签，不全部转成普通小数。
- 无匹配时明确返回“不在当前表范围内”。
- 不允许用无关的默认 `260 mm` 生成结果。

### 4.3 成人女款 205 mm 的边界要正确表达

- 标准成人推荐表与品牌官方表不是同一范围。
- 某品牌可以发布 205 mm 附近的女鞋尺码，不代表标准成人推荐表必须有该行。
- 用户输入 205 mm 时，应分别查询标准数据和品牌数据。
- 标准未覆盖时显示未覆盖；品牌有官方行时可以显示品牌结果。
- 不得把 205 mm 强行映射到 215 mm 标准行。

### 4.4 空档案时不要自动创建虚假人物

当前 `_loadProfiles()` 在没有档案时会自动生成“我的档案”。产品规则要求：

- 首次安装允许没有档案。
- 首页可以直接临时换算。
- 用户主动保存结果或新增档案后才创建档案。

### 4.5 最近换算尚未持久化

当前 `recent` 仅存在内存中，App 重启后丢失。需要保存：

- 输入方式和原始值。
- 规范化毫米值。
- 男款/女款/童款。
- 标准或品牌上下文。
- 结果快照。
- 数据目录版本和时间。

同时实现数量上限、清空确认和旧版本迁移。

### 4.6 档案模型需要稳定 ID

当前档案主要按名称覆盖，正式模型需要：

- `id`
- `name`
- `avatarPath`
- `audience`
- `leftFootMm`
- `rightFootMm`
- `widthPreference`
- `usualSystem`
- `usualSize`
- `createdAt`
- `updatedAt`

档案重名不能覆盖错误的人。

### 4.7 品牌数据必须逐行使用官方值

- “脚长”和“鞋标 CM/JP”是两个不同字段。
- 未发布列保留 `—`。
- 禁止用通用公式补造品牌缺失值。
- 切换男款、女款、童款时保持当前品牌；品牌不覆盖该人群时显示空状态，不偷偷换品牌。
- 品牌 Logo 只有在授权或使用条件明确后进入发布包；开发阶段可以使用中性文字标识。

### 4.8 App 内数据副本需要自动同步

当前完整数据位于 `data/`，Flutter 运行时数据位于 `apps/stride_metric/assets/data/`。后续应增加构建脚本：

1. 校验完整数据。
2. 只导出 App 需要的数据子集。
3. 生成目录版本、哈希和测试夹具。
4. 防止手工复制导致两份数据不一致。

## 5. 建议开发阶段

### 阶段 A：换算正确性

优先级最高，暂时不要接广告 SDK。

1. 重构领域返回类型：
   - `matched`
   - `multipleCandidates`
   - `outOfRange`
   - `unsupported`
   - `invalidInput`
2. 用有效区间替代简单最近值。
3. 已知尺码只允许合法值并精确反查。
4. 完成成人边界、童鞋编号重置和品牌缺失列测试。
5. 所有官方表逐行生成回归测试。
6. 保证换算不经过第三种尺码体系串联。

完成标准：错误输入不会生成“看起来正确”的鞋码。

### 阶段 B：本地档案与历史

1. 移除自动虚假档案。
2. 引入稳定档案 ID。
3. 完成头像、名称、左右脚、脚宽和常穿尺码。
4. 默认使用左右脚中较长值，但界面不反复显示“较长脚”。
5. 持久化最近换算。
6. 实现保存结果时新建或选择档案。
7. 增加数据迁移和损坏恢复测试。

### 阶段 C：Android 真机体验验收

使用用户的 Android 手机和至少一个小屏模拟器检查：

1. 状态栏、安全区和返回按钮位置。
2. 三个 Tab 的底栏高度和触摸区域。
3. 标准/品牌表头吸顶，不穿透、不覆盖状态栏。
4. 品牌选择器、脚长选择器、尺码选择器的滚动和底部安全区。
5. 深色模式覆盖页面、弹层、表格和底栏。
6. mm/cm/in 切换后所有页面同步刷新。
7. 中文、英文、德文、俄文和印地文长文本不溢出。
8. TalkBack 标签、动态字体和横竖屏限制。

建议每修完一个页面，就保存 Android 与 iPhone 两套验收截图。

### 阶段 D：品牌覆盖与数据审计

1. 逐品牌确认男款、女款、童款覆盖。
2. 重点复核 Nike、adidas、ASICS、New Balance、PUMA、Vans。
3. 每张表保留官方 URL、地区、更新时间和适用人群。
4. 校验 adidas 童款完整行数和成人脚长/鞋标双列。
5. 对市场不同、产品系列不同的表分开保存。
6. 数据有疑问时宁可不显示，不推断补值。

### 阶段 E：国际化审校

技术上已经列出 13 种语言，但商店声明“支持某语言”之前仍需完成：

1. 鞋码术语人工审校。
2. 页面、弹层、错误、空状态和权限文案完整性检查。
3. Android/iOS 系统语言自动匹配测试。
4. 首次启动跟随系统语言，用户选择后持久化。
5. 未审校语言回退英文，不展示半成品机器翻译。

首个内部测试包至少保证简体中文和英文完整、自然。

### 阶段 F：广告、隐私和商店准备

核心换算稳定后再开始：

1. 首页最近换算之后预留一个非悬浮横幅广告。
2. 无广告时整个位置折叠。
3. 广告不遮挡输入、结果、导航或按钮。
4. 不把脚长、档案、头像、脚宽和历史传给广告 SDK。
5. 准备隐私政策、广告披露、数据安全表和 App Tracking Transparency 判断。
6. 最后再考虑买断去广告和购买恢复。

### 阶段 G：发布

1. 确认产品名 `StrideMetric` 和商标风险。
2. 确认 Android application ID 与 iOS bundle identifier：
   `com.stridemetric.shoe`。
3. 完成签名、版本号、启动图、商店图和描述。
4. Android 内测轨道。
5. iOS TestFlight。
6. 崩溃、ANR、冷启动、离线启动和低端机测试。
7. Google Play 与 App Store 分阶段发布。

HarmonyOS 暂不与 Android/iOS 首版并行；先保持领域层纯 Dart，等首版稳定后单独评估适配路线。

## 6. 每次修改必须运行

在仓库根目录：

```powershell
cd C:\Users\27433\Documents\dd-openSource\projects\stride-metric
node scripts\validate-data.mjs

cd apps\stride_metric
flutter pub get
flutter analyze
flutter test
```

连接 Android 手机后：

```powershell
flutter devices
flutter run
```

提交前检查：

```powershell
git status --short
git diff --check
```

不得提交：

- APK、AAB、IPA。
- `build/`、`.dart_tool/`、IDE 缓存。
- `local.properties`、签名文件和密码。
- ISO/GB 标准原文、扫描图片或版权不明的品牌 Logo。

## 7. 下一条 Codex 任务建议只做这一件事

不要在一个任务中同时重写引擎、接广告、补所有品牌和准备上架。下一条任务建议先完成“换算引擎正确性与回归测试”：

1. 检查当前领域模型和 JSON 字段。
2. 用明确的匹配结果替换 `nearest()` 静默兜底。
3. 修复已知尺码精确反查。
4. 正确处理 205 mm 女款、成人上下界和童鞋编号重置。
5. 为标准与品牌官方行建立逐行测试。
6. 保持现有 UI，只做接入新返回状态所必需的最小调整。

只有这一阶段通过后，再进入档案持久化与真机 UI 验收。

## 8. 可直接复制给新 Codex 任务的提示词

```text
请继续开发 StrideMetric。

正式仓库：
C:\Users\27433\Documents\dd-openSource

项目目录：
C:\Users\27433\Documents\dd-openSource\projects\stride-metric

开始前完整阅读：
1. NEXT_STEPS.zh-CN.md
2. docs/architecture/flutter-screen-logic-v1.zh-CN.md
3. docs/architecture/system-architecture.zh-CN.md
4. DATA_NOTICE.md

本次只完成“换算引擎正确性与回归测试”：
- 禁止使用 nearest() 为越界或无效输入静默生成结果；
- 已知尺码必须精确匹配当前受众和体系；
- 正确处理 205 mm 女款边界、成人上下界和童鞋编号重置；
- 标准与品牌未发布值不得用公式补造；
- 建立逐行和边界回归测试；
- 保持现有 UI，只做接入明确错误/未覆盖状态所需的最小调整。

完成后必须运行：
node scripts\validate-data.mjs
flutter analyze
flutter test

不要修改 C:\Users\27433\Documents\炫酷前端，也不要提交标准原文、扫描图片、APK、构建缓存、密钥或版权不明的品牌 Logo。
```

## 9. 首版完成定义

首版只有同时满足以下条件才可进入商店准备：

- 标准与品牌数据审计无错误。
- 所有官方表逐行测试通过。
- 无静默外推和无关默认值回退。
- 男款、女款、童款及 mm/cm/in 全流程通过。
- 档案和历史重启后正确恢复。
- 13 种语言键完整，商店声明语言已人工审校。
- 小屏 Android、主流 Android、iPhone 真机布局通过。
- 深色模式、TalkBack/VoiceOver 和动态字体通过。
- 离线首次启动可用。
- 广告不影响换算，不读取尺码隐私数据。
- 隐私政策、商店披露、签名和发布素材齐备。
