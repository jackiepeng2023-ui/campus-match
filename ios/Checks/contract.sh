#!/usr/bin/env bash
# iOS 契約測試：用 App 的 APIClient.swift 與 Models.swift 對執行中的後端跑一遍 iOS 會用到的 API（Linux／macOS 皆可）。
# 用法：ios/Checks/contract.sh [baseURL] [示範帳號密碼]     需要：swiftc 在 PATH 上、後端以示範資料啟動（會寫入資料）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$(mktemp -d)/contract"
swiftc -swift-version 5 "$HERE/../CampusMatch/Models.swift" "$HERE/../CampusMatch/APIClient.swift" "$HERE/contract/main.swift" -o "$BIN"
"$BIN" "${1:-http://localhost:8080}" "${2:-demo1234}"
