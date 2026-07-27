# 编码设计与实施计划

## 工程结构

建议建立 Flutter monorepo：

```text
apps/
  size_app/
packages/
  size_domain/
  size_catalog/
  size_storage/
  size_ui/
tool/
  data_builder/
data/
  原始可审计 JSON
test/
  fixtures/
```

职责：

- `size_domain`：纯 Dart 换算和推荐规则。
- `size_catalog`：只读尺码库访问、索引、来源查询。
- `size_storage`：用户档案、历史、收藏和设置。
- `size_ui`：设计令牌、通用表单、结果卡、来源卡。
- `size_app`：页面、路由、平台 SDK 和依赖装配。
- `data_builder`：验证 JSON，生成 SQLite 和版本清单。

## 领域对象

### 输入

- `FootMeasurement`
- `BodyMeasurements`
- `KnownShoeSize`
- `Audience`
- `ChildStage`
- `BrandContext`
- `ProductFamilyContext`
- `GarmentContext`
- `FitPreference`

### 输出

- `Recommendation`
- `SizeCandidate`
- `Confidence`
- `Provenance`
- `FitWarning`
- `MeasurementConflict`
- `UnsupportedReason`

领域对象使用整数毫米保存长度。来源为英寸或厘米时，保留原始值，并使用确定的换算函数生成毫米，避免浮点比较导致边界漂移。

## 核心接口

```dart
abstract interface class ShoeConversionEngine {
  ShoeRecommendation convert(ShoeConversionRequest request);
}

abstract interface class ClothingRecommendationEngine {
  ClothingRecommendation recommend(ClothingRequest request);
}

abstract interface class SizeCatalog {
  CatalogSnapshot get snapshot;
  List<BrandChart> findCharts(ChartQuery query);
  SourceRecord sourceById(String id);
}
```

引擎只接收接口，不知道 SQLite、Flutter 或网络的存在。

## 区间匹配规则

- 源表明确写闭区间时按闭区间。
- 相邻区间共享边界时，返回两个候选并根据版型偏好排序。
- 输入位于两个离散鞋码脚长之间时，默认推荐不小于脚长的下一码，但必须服从品牌官方说明。
- 超出首尾范围时返回 `outOfRange`，不线性外推。
- 所有四舍五入只能发生在显示层；匹配使用规范化整数。

## 数据包版本

```text
catalogVersion: 2026.07.26.1
schemaVersion: 1
minimumAppVersion: ...
createdAt: ...
sourceRegistryHash: ...
catalogSha256: ...
signature: ...
```

App 日志和用户报告引用 `catalogVersion`，这样才能复现结果。

## 开发阶段

### 阶段 0：数据基线

已完成：

- 标准和品牌数据分层。
- 来源登记。
- JSON 结构校验。
- 品牌覆盖目标。
- 源异常隔离。

完成门槛：`node scripts/validate-data.mjs` 返回 `ok: true`。

### 阶段 1：领域引擎

1. 定义稳定领域对象和错误类型。
2. 实现单位转换。
3. 实现鞋类标准表查询。
4. 实现品牌覆盖优先级。
5. 实现儿童编号阶段。
6. 实现服装多维范围匹配。
7. 实现可信度和解释键。

不做 UI，先用测试固定正确性。

### 阶段 2：数据构建器

1. JSON Schema 或等价结构验证。
2. 来源 ID 和数据集 ID 外键检查。
3. 单调性与重复键检查。
4. 生成只读 SQLite。
5. 生成哈希、版本和测试夹具。
6. 输出人类可读审计报告。

### 阶段 3：鞋类最小可用产品

1. 成人/儿童选择。
2. 脚长和已知尺码输入。
3. 品牌和产品系列选择。
4. 推荐结果、备选和来源解释。
5. 单位切换和测量教学。

### 阶段 4：档案与离线体验

1. 多人档案。
2. 左右脚、脚宽和实际穿着反馈。
3. 最近换算和收藏品牌。
4. 导出、删除和隐私说明。

### 阶段 5：服装

1. 上衣。
2. 下装。
3. 儿童服装。
4. 版型偏好。
5. 测量冲突解释。

### 阶段 6：商业化与上架

等核心价值稳定后再加入：

- 一次性买断去广告。
- 轻量广告。
- 激励广告只能解锁非必要便利功能，不能降低免费换算准确性。
- App Store/Google Play 内购恢复。
- 隐私同意和商店披露。

## 测试策略

### 数据逐行测试

每个官方表格行生成测试：

- 由任一标签查询能回到同一规范记录。
- 目标体系结果与官方行一致。
- 脚长在边界内命中正确。
- 排除值永不进入结果。

### 属性测试

- mm -> cm -> mm 不丢失规范值。
- 尺码序列在同一阶段内保持单调。
- 跨儿童编号重置不误合并。
- 任意换算不经过第三体系串联。
- 超出范围永不外推。

### 冲突测试

- 品牌表与标准表不同时优先品牌，并保留差异说明。
- 产品系列覆盖品牌通用表。
- 市场不匹配时不可使用该表。
- Tall/Petite 等版型不可退化为普通标签。

### UI 测试

- 动态字体最大档。
- 小屏和大屏。
- 中英文。
- cm/in 小数输入。
- VoiceOver/TalkBack 语义。
- 深色和高对比度。
- 离线首次启动。

### 发布门槛

- 领域层分支覆盖率建议不低于 95%。
- 所有官方表逐行测试通过。
- 数据审计 0 错误。
- 无 P0/P1 无障碍问题。
- 隐私清单与实际 SDK 一致。
- 商店截图不得宣称“100% 准确”或“适用于所有品牌”。

## 首轮编码顺序

1. 创建 Flutter workspace 和四个内部 package。
2. 写领域模型与结果协议。
3. 将现有 JSON 转换为测试夹具。
4. 先实现鞋类脚长枢轴和品牌优先级。
5. 用 GB/T 儿童完整表及 Nike/adidas/New Balance 儿童表做最难边界测试。
6. 实现服装多测量范围匹配。
7. 再接页面。

这样第一批代码就围绕“正确性和解释能力”，不会被页面状态或广告 SDK 绑住。
