# StrideMetric 国际化规范 V1

## 1. 已支持语言

首发版本完整覆盖以下 13 个语言环境：

1. English（`en`）
2. Türkçe（`tr`）
3. Deutsch（`de`）
4. Español（`es`）
5. Français（`fr`）
6. Italiano（`it`）
7. Português (Brasil)（`pt-BR`）
8. 日本語（`ja`）
9. 한국어（`ko`）
10. 简体中文（`zh-CN`）
11. Русский（`ru`）
12. Nederlands（`nl`）
13. हिन्दी（`hi`）

首次启动跟随系统语言；系统语言不在支持列表时使用英语。用户可以在“档案 → 设置 → 语言”中覆盖系统语言，选择结果通过本地偏好设置持久化。

## 2. 翻译边界

- 翻译页面标题、导航、按钮、字段名、对话框、空状态、帮助、隐私、错误提示和动态句子。
- `EU`、`UK`、`US`、`JP`、`KR` 等国际尺码标识保持不变。
- Nike、adidas、ASICS 等品牌名称保持官方拼写。
- 数字使用统一紧凑格式，去掉没有意义的末尾零。
- 长度单位 `mm`、`cm`、`in` 保持国际缩写；单位的完整名称按界面语言翻译。
- 用户自定义档案名称不翻译。

## 3. 技术实现

- Flutter 使用官方 `flutter_localizations`。
- 语言枚举、Locale 映射、文案表和插值逻辑位于
  `apps/stride_metric/lib/l10n/app_localizations.dart`。
- `MaterialApp.locale` 由 `AppState.language` 驱动。
- `SharedPreferences` 保存用户语言标签。
- 所有页面通过 `context.l10n` 读取当前语言，切换后立即重建，无需重启应用。

## 4. 完整性保护

自动化测试必须保证：

- 支持语言数量固定为 13。
- 每个文案键都有 13 个非空翻译。
- `pt-BR`、`zh-CN` 等区域语言标签能够正确匹配。
- 用户选择语言后能够跨会话恢复。
- 中文主流程仍可完成换算并进入结果页。

发布新功能时，未补齐 13 种语言的文案不得合入发布构建。
