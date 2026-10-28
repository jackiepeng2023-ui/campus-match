# CampusMatch iOS（SwiftUI，iOS 17+）

學生端核心功能：登入、推薦給我的案件、申請／回應邀請、案件詳情（發案方也可查看推薦與核准）、結案投票、雙盲互評、成長儀表板與 AI Prompt、通知與 APNs 推播。與網頁共用同一套 REST API。

## 建立 Xcode 專案（二選一）

### A. XcodeGen（推薦，1 分鐘）
```bash
brew install xcodegen
cd ios && xcodegen generate
open CampusMatch.xcodeproj
```

### B. 手動（3 分鐘）
1. Xcode → File → New → Project → iOS → App；Product Name `CampusMatch`，Interface SwiftUI，Language Swift。
2. 刪除範本產生的 `ContentView.swift` 與 `CampusMatchApp.swift`。
3. 把 `ios/CampusMatch/*.swift` 全部拖進專案（勾選 Copy items if needed）。
4. Target → Info → 新增 `App Transport Security Settings` → `Allow Arbitrary Loads = YES`（Demo 連 http://localhost 用）。
5. 要推播：Signing & Capabilities → `+ Capability` → Push Notifications；Background Modes 勾 Remote notifications。

## 執行
1. 先啟動後端（見根目錄 README），確認 http://localhost:8080/api/v1/health 回 `{"status":"ok"}`。
2. 模擬器直接 Run；登入頁預設 API 為 `http://localhost:8080`。實機請點「API 伺服器設定」改成 Mac 的區網 IP（例如 `http://192.168.1.20:8080`）或 Azure 網址。
3. 示範帳號密碼皆為 `demo1234`：`student002@example.edu`（資工前端）、`student005@example.edu`（創設 UI/UX）、`student007@example.edu`（自評上調）、`student001@example.edu`（企管發案方）。

## APNs 推播（D44）
- 需要 Apple Developer 帳號；在 Apple Developer → Keys 建立 APNs Auth Key（.p8），記下 Key ID、Team ID。
- 後端以環境變數啟動：`APNS_KEY_PATH=/path/AuthKey_XXXX.p8 APNS_KEY_ID=XXXX APNS_TEAM_ID=YYYY APNS_BUNDLE_ID=tw.edu.fcu.campusmatch APNS_SANDBOX=true`。
- 推播只能在實機測試；模擬器仍會收到站內通知（首頁右上角鈴鐺）。
- 未設定金鑰時後端只記錄 log，其餘功能不受影響。

## 檔案
| 檔案 | 內容 |
|---|---|
| `Models.swift` | 與 API 對應的 Codable 模型、標籤、日期格式 |
| `APIClient.swift` | URLSession async/await 客戶端、錯誤處理、token 儲存 |
| `AppState.swift` | 登入者、參考資料、錯誤訊息 |
| `CampusMatchApp.swift` | App 進入點、APNs AppDelegate |
| `HomeView.swift` | 待回覆、推薦給我的案件、我的案件 |
| `CasesView.swift` / `CaseDetailView.swift` | 案件搜尋、詳情、申請／邀請／核准、結案投票、推薦名單 |
| `ReviewView.swift` | 雙盲互評表單 |
| `GrowthView.swift` | 雷達圖（Canvas）、時間軸、AI Prompt |
| `ProfileView.swift` | 成績、技能檔、得獎、可投入時間、公開檔案、刪除帳號 |
| `CoursePickerView.swift` | 科目清單填分數：系所 × 學制 × 入學學年度 → 必修／選修／通識／搜尋全校，點科目填分數，沒有技能對照的科目可自填技能送審 |
| `NotificationsView.swift` | 站內通知 |
| `Components.swift` | ScoreCard、Pill、Stars、FlowLayout 等共用元件 |
