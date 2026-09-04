#!/usr/bin/env bash
# 酒馆战棋 - 构建脚本
# 用法：./build.sh [assembleHap|clean|...]
set -e

# 自动定位 DevEco 自带 SDK
DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-C:/Program Files/Huawei/DevEco Studio/sdk}"
export DEVECO_SDK_HOME

TASK="${1:-assembleHap}"
node hvigorw.js "$TASK" --no-daemon
