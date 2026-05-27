#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "==> 构建 Android Debug APK..."

# Unset mirror URLs to use official Flutter storage
# (mirrors may not have the latest engine artifacts)
unset FLUTTER_STORAGE_BASE_URL
unset PUB_HOSTED_URL

flutter build apk --debug

APK="build/app/outputs/flutter-apk/app-debug.apk"
echo "     Debug ✓ $(ls -lh "$APK" | awk '{print $5}')"

# Auto-deploy if device is connected
DEVICE=$(adb devices 2>/dev/null | grep -v "List of" | grep "device$" | head -1 | awk '{print $1}')
if [ -n "$DEVICE" ]; then
    echo "==> 安装到设备: $DEVICE"
    adb -s "$DEVICE" install -r "$APK"
    adb -s "$DEVICE" shell am start -n com.assertsum.asset_sum/.MainActivity
    echo "     有数 ✓ 已启动"
else
    echo "     (无设备连接，跳过安装)"
fi

echo ""
echo "==> 构建 Android Release APK..."
flutter build apk --release

REL="build/app/outputs/flutter-apk/app-release.apk"
echo "     Release ✓ $(ls -lh "$REL" | awk '{print $5}')"
echo "==> 完成"
