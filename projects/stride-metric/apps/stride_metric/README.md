# StrideMetric

离线国际鞋码换算 App，使用 Flutter 同时面向 Android 与 iOS。

## 当前标识

- 产品名：StrideMetric
- 中文商店副标题：鞋码换算
- Android applicationId：`com.stridemetric.shoe`
- iOS bundle identifier：`com.stridemetric.shoe`
- 版本：`1.0.0+1`

正式提交商店前，仍需完成同名商标、App Store 和 Google Play 名称占用核查。

## Android Studio 运行

当前仓库上级目录包含中文。Windows 版 Flutter 的着色器编译器可能无法向中文路径写文件，因此推荐以下两种方式：

1. 查看现有效果：直接安装 `artifacts/StrideMetric-debug.apk`。
2. 用 Android Studio 调试：把整个仓库复制到纯英文目录（例如 `C:\dev\stride-metric`），然后打开 `apps/stride_metric`。

在英文目录中：

1. 确认 Flutter SDK 指向 `E:\flutter`。
2. 执行 `flutter pub get`。
3. Android 手机开启开发者选项和 USB 调试，用数据线连接电脑。
4. 在 Android Studio 顶部设备列表选中手机，点击 Run。

如果设备列表没有手机，先执行：

```powershell
adb devices
flutter devices
```

当前电脑还需要在 Android Studio 的 SDK Manager 中安装 Android SDK Command-line Tools，并接受 Android licenses。

如果只需从当前中文目录重新构建 APK，可运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_android_debug.ps1
```

脚本会临时创建纯英文构建镜像，完成后把 APK 放回 `artifacts/`，并删除临时镜像。

## 常用验证命令

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

## 数据与架构

- 标准数据：`assets/data/reference/`
- 品牌官方数据：`assets/data/brand/`
- 图标源文件：`assets/branding/app-icon-source.png`
- 页面逻辑说明：`../../docs/architecture/flutter-screen-logic-v1.zh-CN.md`
- 国际化规范：`../../docs/architecture/internationalization-v1.zh-CN.md`
- 品牌与平台决策：`../../docs/architecture/app-brand-platform-decision.zh-CN.md`

内部统一使用毫米保存脚长；界面根据设置显示 mm、cm 或 in。品牌表严格区分“实测脚长”和“鞋标”，不使用通用公式填补官方未发布的单元格。

## 国际化

当前完整支持 English、Türkçe、Deutsch、Español、Français、Italiano、Português (Brasil)、日本語、한국어、简体中文、Русский、Nederlands 和 हिन्दी。首次启动跟随系统语言，不支持的系统语言回退到英语；用户也可以在设置中选择语言，选择结果保存在本机。

## 广告策略

当前开发版仅保留底部静态广告占位，不接入真实广告 SDK。正式接入时只在内容底部使用非粘性横幅，并在有广告填充时显示，避免遮挡换算按钮、表格或底部导航。

## HarmonyOS

先完成 Android/iOS 首发。HarmonyOS 作为后续独立适配目标；不要把未经验证的 Flutter 鸿蒙兼容层直接并入首发分支。
