#!/bin/bash
set -e
cd "$(dirname "$0")"

export SQLITE3_DIST_DISABLE_DOWNLOAD=true

echo "==> 构建 iOS Simulator..."
flutter build ios --debug --simulator

# 获取当前已启动的模拟器
BOOTED=$(xcrun simctl list devices | grep "Booted" | head -1 | grep -oE '[A-F0-9-]{36}')
if [ -z "$BOOTED" ]; then
    echo "No booted simulator found, trying to boot one..."
    SIM_UUID=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | grep -oE '[A-F0-9-]{36}')
    if [ -n "$SIM_UUID" ]; then
        xcrun simctl boot "$SIM_UUID" 2>/dev/null || true
        open -a Simulator
        sleep 5
        BOOTED="$SIM_UUID"
    fi
fi

if [ -n "$BOOTED" ]; then
    echo "==> 安装到模拟器: $BOOTED"
    xcrun simctl install "$BOOTED" build/ios/iphonesimulator/Runner.app
    xcrun simctl launch "$BOOTED" com.assertsum.assetSum
    echo "     有数 ✓ 已启动"
else
    echo "     (无可用模拟器)"
fi

echo "==> 完成"
