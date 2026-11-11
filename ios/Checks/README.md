# ios/Checks：沒有 Xcode 時的兩支檢查

這個資料夾不屬於 App（`ios/project.yml` 的 sources 只有 `CampusMatch/`）。說明見 [`ios/README.md`](../README.md#在-linux-上的檢查)。

| 檔案 | 用途 |
|---|---|
| `contract.sh`、`contract/main.swift` | 契約測試：App 的 `APIClient.swift`＋`Models.swift` 對執行中的後端跑 21 項 |
| `typecheck.sh`、`stubs/SwiftUI.swift`、`stubs/UIKit.swift` | 型別檢查：以介面樁（只有簽章）檢查 17 個原始檔 |

`stubs/` 裡的檔案**不是** SwiftUI，也不能用來執行 App；簽章依 iOS 17 SDK 的公開介面手寫，只為了讓 Swift 編譯器能檢查 App 自己的程式。通過這兩支檢查不等於 Xcode 編譯通過。
