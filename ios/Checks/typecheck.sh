#!/usr/bin/env bash
# 在沒有 Xcode 的環境（Linux／CI）對 iOS App 做型別檢查：先把介面樁編成 UIKit、SwiftUI 兩個模組，再檢查 App 原始碼。
# 需要 Swift 5.9 以上的工具鏈（swiftc 在 PATH 上）。CampusMatchApp.swift 用到 UserNotifications 與 UIApplicationDelegate，不在檢查範圍。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$(mktemp -d)}"
swiftc -swift-version 5 -parse-as-library -emit-module -module-name UIKit -emit-module-path "$OUT/UIKit.swiftmodule" "$HERE/stubs/UIKit.swift"
swiftc -swift-version 5 -parse-as-library -emit-module -module-name SwiftUI -I "$OUT" -emit-module-path "$OUT/SwiftUI.swiftmodule" "$HERE/stubs/SwiftUI.swift"
cd "$HERE/../CampusMatch"
FILES=$(ls *.swift | grep -v '^CampusMatchApp.swift$')
FAILED=0
for f in $FILES; do          # 一次以一個檔案為主檔：每個檔案的診斷都會完整列出，不會因為別的檔案先出錯而被略過
  OTHERS=$(echo "$FILES" | tr ' ' '\n' | grep -v "^$f$")
  if ! swiftc -frontend -typecheck -swift-version 5 -parse-as-library -warnings-as-errors -module-name CampusMatch -I "$OUT" -primary-file "$f" $OTHERS; then FAILED=$((FAILED+1)); fi
done
if [ "$FAILED" -gt 0 ]; then echo "typecheck FAILED: $FAILED file(s)"; exit 1; fi
echo "typecheck ok: $(echo $FILES | wc -w) files"
