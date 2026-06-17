#!/bin/bash

# 测试Flutter项目是否能编译
echo "正在测试Flutter项目..."

cd /workspace/flutter-personal-accounting

# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 分析代码
flutter analyze

echo "测试完成！"
