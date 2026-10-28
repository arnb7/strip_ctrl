#!/usr/bin/env bash
set -euo pipefail

echo "===> Checking packages/led_core"
cd packages/led_core
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
cd ../..

echo "===> Checking app"
cd app
flutter test
cd ..

echo "===> All checks passed cleanly across the entire monorepo!"
