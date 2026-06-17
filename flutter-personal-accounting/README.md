# 个人记账应用

一个简单易用的Flutter个人记账应用。

## 功能特性

- ✅ 记录收入和支出
- ✅ 分类管理（餐饮、交通、购物等）
- ✅ 统计总收支
- ✅ 本地数据存储

## 技术栈

- Flutter 3.0.0
- Dart 2.17.0
- sqflite (本地数据库)
- path_provider (文件路径)
- intl (日期格式化)

## 安装依赖

```bash
flutter pub get
```

## 运行应用

```bash
# Web版
flutter run -d chrome

# Android版 (需要Android SDK)
flutter run -d android

# 构建Android APK
flutter build apk
```

## 项目结构

```
lib/
  ├── main.dart          # 主应用入口
  ├── models/            # 数据模型
  ├── providers/         # 状态管理
  ├── screens/           # 界面页面
  └── services/          # 服务类
```

## 注意事项

由于开发环境限制，当前版本使用了兼容的依赖版本以确保稳定性。

## 下一步计划

- [ ] 添加图表统计
- [ ] 支持数据导出
- [ ] 添加预算功能
- [ ] 支持多币种

## 许可证

MIT License
