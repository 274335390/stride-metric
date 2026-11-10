# 离线鞋码与服装尺码工具系统架构

## 架构目标

系统首先解决“给出可解释、可追溯、不会装作精确的推荐”，其次才是展示更多尺码体系。

核心约束：

- Android 与 iOS 共用一套业务逻辑。
- 主功能完全离线。
- 无品牌数据时不伪造品牌结果。
- 数据可审计、可回滚、可升级。
- 用户测量和家庭档案只保存在设备本地。
- 换算引擎与 UI、广告、商店 SDK 解耦。

## 技术选型

首选 Flutter + Dart。

原因：

- 单一代码库覆盖 Android/iOS，交互和排版一致。
- 适合离线、表单、列表、单位切换和高质量动画。
- Dart 可以把换算核心做成纯函数包，容易做大量边界测试。
- 原生桥接只保留给内购、广告、隐私同意和商店能力。

建议组件：

| 能力 | 选择 |
|---|---|
| 状态管理 | Riverpod |
| 路由 | go_router |
| 本地用户数据库 | Drift + SQLite |
| 不可变模型 | Freezed 或等价代码生成 |
| JSON | json_serializable |
| 多语言 | Flutter intl/ARB |
| 日志 | 本地结构化日志，默认不上传 |
| 崩溃统计 | 上线前再接入，需隐私同意 |

依赖版本在创建工程时锁定到当日 Flutter stable 的兼容组合，不在架构文档中写死易过时的版本号。

## 总体分层

```text
presentation
  screens / widgets / view models / localization
        |
application
  use cases / orchestration / result explanation
        |
domain
  conversion engine / recommendation rules / confidence / provenance
        |
data
  read-only size catalog / user profiles / update packages / repositories
        |
platform
  SQLite / files / IAP / ads / privacy consent / share
```

依赖只能从外层指向内层。`domain` 不导入 Flutter，不依赖数据库和网络，因此可独立测试。

## 数据存储策略

不是简单地“全部放前端”或“必须建服务器数据库”，而是分成两类：

### 只读尺码数据

- 仓库内以可审计 JSON 保存原始结构化数据。
- 构建时执行验证、规范化和索引生成。
- App 包内携带只读 SQLite 数据包或紧凑二进制索引。
- 首版不需要服务器即可完整使用。

选择构建时生成只读 SQLite，而不是运行时反复扫描 JSON，原因是：

- 可以按品牌、市场、受众、品类、尺码快速查询。
- 数据表有外键和唯一性约束。
- 更新包可以整库替换并校验。
- 原始 JSON 仍然保留为审计和开发来源。

### 用户本地数据

独立 Drift 数据库保存：

- 多人档案。
- 脚长、脚宽及身体测量。
- 常用品牌和偏好。
- 收藏、最近换算。
- 用户对某品牌/鞋款的实际穿着反馈。
- 本地设置和同意状态。

尺码目录与用户数据库分离，更新目录时不会破坏个人资料。

## 数据构建流水线

```text
官方来源/合法取得的标准证据
  -> 人工录入或受控提取
  -> 原始 JSON
  -> JSON/表格结构检查
  -> 单调性、边界、编号重置、单位检查
  -> 来源与许可检查
  -> 生成规范化记录
  -> 生成只读 catalog.sqlite
  -> 生成内容哈希和版本清单
  -> 引擎回归测试
  -> App 打包
```

任何步骤失败都禁止发布数据包。

## 换算优先级

从高到低：

1. 具体 SKU 或产品型号覆盖。
2. 产品系列覆盖，例如 Converse Chuck Taylor。
3. 品牌 + 市场 + 受众 + 品类 + 版型系列。
4. 品牌通用表。
5. 国家标准。
6. ISO 技术参考。
7. 市场惯例，仅作为低可信高级选项。

高层规则可以覆盖低层结果，但必须保留被覆盖结果和原因，以便解释。

## 鞋类换算原则

### 统一枢轴

所有可以精确计算的换算都以脚长毫米或官方表中的测量范围为枢轴：

```text
输入尺码 -> 对应脚长/适用范围 -> 目标体系候选
```

禁止：

```text
US -> EU -> UK -> JP
```

串联换算会累积步长差异和四舍五入误差。

### 标签与测量分离

数据模型必须区分：

- `measuredFootLengthMm`：用户实际测得。
- `labelCm` / `labelJp`：品牌印在鞋盒或鞋舌上的标签。
- `effectiveLastLengthMinMm/MaxMm`：标准表中的有效楦长范围。

它们不能共用一个 `cm` 字段。

### 儿童阶段

儿童结果键必须包含 `stage`：

- infant/toddler
- little_kids
- big_kids/youth

同一个数字在不同阶段不是同一码。

## 服装推荐原则

服装不是“国家码互换”，而是范围匹配问题：

```text
身体测量 + 人群 + 品类 + 品牌 + 市场 + 版型偏好
  -> 每个测量落入的候选尺码
  -> 冲突分析
  -> 推荐尺码、备选尺码、原因
```

示例：胸围落在 M，腰围落在 L。

返回：

- 推荐 L，如果该品类按较大围度优先。
- 备选 M，说明会更贴身。
- 冲突字段：胸围、腰围。
- 建议查看具体商品版型或实物评价。

不得只返回一个没有解释的 `L`。

## 统一结果协议

每次换算返回：

```json
{
  "status": "resolved",
  "primary": {
    "label": "EU 42",
    "confidence": "brand_exact"
  },
  "alternatives": [],
  "basis": {
    "type": "brand_chart",
    "brandId": "example",
    "market": "US",
    "datasetId": "example_dataset",
    "sourceIds": ["example_source"],
    "retrievedAt": "2026-07-26"
  },
  "inputInterpretation": {
    "measurementMm": 265,
    "stage": "adult"
  },
  "warnings": [],
  "explanationKeys": ["matched_official_brand_range"]
}
```

`status` 包括：

- `resolved`
- `multiple_candidates`
- `out_of_range`
- `unsupported`
- `source_conflict`

## 可信度模型

不要伪造 87% 之类没有统计依据的数字。使用可解释枚举：

- `brand_product_exact`
- `brand_exact`
- `brand_reference`
- `standard_reference`
- `market_approximation`
- `insufficient_data`

UI 可将其显示为“高可信 / 品牌参考 / 标准参考 / 数据不足”，详情页解释依据。

## 离线更新机制

首版随 App 发布完整基线数据。后续可增加可选在线数据包：

1. App 下载签名清单。
2. 校验 schema 版本、App 最低版本、SHA-256 和签名。
3. 下载到临时文件。
4. 完整运行快速结构检查。
5. 原子替换只读目录。
6. 保留上一个版本用于回滚。

更新失败继续使用旧版本，绝不让在线更新破坏离线功能。

## 隐私与安全

- 不要求账号。
- 身体测量和家庭档案默认仅本地。
- 分享结果前预览将要导出的内容。
- 广告和分析不得读取具体身体测量。
- 若加入云同步，必须作为独立的明确同意功能，不能成为换算前提。
- 数据包只接受项目签名，避免被篡改。

## 观测与问题反馈

默认只记录不含个人测量的本地诊断：

- 数据集版本。
- 输入类型。
- 结果状态。
- 规则路径。
- 异常代码。

“报告数据问题”生成可复制的脱敏报告，用户自行选择是否发送。报告包含数据集和行键，不包含姓名或身体数值，除非用户主动勾选。
