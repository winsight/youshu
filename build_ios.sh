#!/bin/bash
set -e
cd "$(dirname "$0")"

# Skip sqlite3 native asset download (using sqlite3_flutter_libs instead)
export SQLITE3_DIST_DISABLE_DOWNLOAD=true

echo "==> 构建 iOS Simulator..."
flutter build ios --debug --simulator

# Find available iPhone simulator
SIM=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | sed 's/.*(\(.*\))/\1/')

if [ -z "$SIM" ]; then
    echo "No iPhone simulator found, trying to boot one..."
    SIM_UUID=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | grep -oE '[A-F0-9-]{36}')
    if [ -n "$SIM_UUID" ]; then
        xcrun simctl boot "$SIM_UUID" 2>/dev/null || true
        open -a Simulator
        sleep 5
    fi
fi

if [ -n "$SIM_UUID" ]; then
    echo "==> 安装到模拟器..."
    xcrun simctl install booted build/ios/iphonesimulator/Runner.app
    xcrun simctl launch booted com.assertsum.asset-sum
    echo "     有数 ✓ 已启动"
fi

echo "==> 完成"
