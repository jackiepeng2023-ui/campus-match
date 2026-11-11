# CampusMatch iOS（SwiftUI，iOS 17+）

學生端功能：登入、AI 助理（說出目標 → 看到每一步 → 按確認才執行）、競賽推薦與組隊（三個 Agent）、推薦給我的案件、申請／回應邀請、案件詳情（發案方也可查看推薦與核准）、結案投票、雙盲互評、Skill Profile（技能／三階等級／證據，證照與作品集）、成長儀表板與知識圖譜、通知與 APNs 推播。與網頁共用同一套 REST API。

> **驗證狀態（請先讀）**：這個 App 沒有在 Xcode 上編譯與執行過（開發環境是 Linux，沒有 Xcode 與 SwiftUI）。已做的檢查見〈[在 Linux 上的檢查](#在-linux-上的檢查)〉：資料層（`APIClient.swift`＋`Models.swift`）以實際後端跑過 21 項契約測試；畫面程式以手寫的 SwiftUI 介面樁做過型別檢查。第一次用 Xcode 開啟時仍可能遇到介面樁沒有涵蓋的編譯問題。

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
3. 示範帳號密碼皆為 `demo1234`：`student002@example.edu`（資工前端）、`student005@example.edu`（創設 UI/UX）、`student007@example.edu`（自述偏高）、`student001@example.edu`（企管發案方）。
4. 分頁：首頁／AI 助理／競賽／案件／我的檔案；成長儀表板從「我的檔案 → 成長儀表板與知識圖譜」進入。

## APNs 推播（D44）
- 需要 Apple Developer 帳號；在 Apple Developer → Keys 建立 APNs Auth Key（.p8），記下 Key ID、Team ID。
- 後端以環境變數啟動：`APNS_KEY_PATH=/path/AuthKey_XXXX.p8 APNS_KEY_ID=XXXX APNS_TEAM_ID=YYYY APNS_BUNDLE_ID=tw.edu.fcu.campusmatch APNS_SANDBOX=true`。
- 推播只能在實機測試；模擬器仍會收到站內通知（首頁右上角鈴鐺）。
- 未設定金鑰時後端只記錄 log，其餘功能不受影響。

## 檔案
| 檔案 | 內容 |
|---|---|
| `Models.swift` | 與 API 對應的 Codable 模型、標籤、日期格式；AI 助理卡片的具名型別；**顯示用文字**（extension，只用 Foundation） |
| `APIClient.swift` | URLSession async/await 客戶端、錯誤處理、token 儲存 |
| `AppState.swift` | 登入者、參考資料、錯誤訊息 |
| `CampusMatchApp.swift` | App 進入點、APNs AppDelegate |
| `RootTabView.swift` | 五個分頁 |
| `HomeView.swift` | 待回覆、推薦給我的案件、我的案件 |
| `AssistantView.swift` | AI 助理：對話、執行軌跡（每一步的 Agent、工具、耗時）、卡片（能力盤點／競賽／隊友／教師）、待確認動作（確認／取消） |
| `CompetitionsView.swift` | 競賽 Agent 的推薦與全部競賽；詳情頁呼叫學生 Agent（互補隊友）、教師 Agent（指導老師），起草組隊案件 |
| `CasesView.swift` / `CaseDetailView.swift` | 案件搜尋、詳情、申請／邀請／核准、結案投票、推薦名單 |
| `ReviewView.swift` | 雙盲互評表單 |
| `ProfileView.swift` | Skill Profile（分數只有本人看得到、三階等級、可信狀態、逐筆證據）、證照／作品集／自我評估、修課成績、得獎、可投入時間、AI 同意、刪除帳號 |
| `CoursePickerView.swift` | 科目清單填分數：系所 × 學制 × 入學學年度 → 必修／選修／通識／搜尋全校 |
| `GrowthView.swift` / `KnowledgeGraphView.swift` | 雷達圖、時間軸、AI Prompt；證據 → 技能 → 分類的力導向圖（Canvas）、匯出 Obsidian Vault |
| `NotificationsView.swift` | 站內通知 |
| `Components.swift` | ScoreCard、Pill、SkillChip、TrustBadge、Stars、FlowLayout 等共用元件 |

## 在 Linux 上的檢查

`Checks/` 不屬於 App（`project.yml` 的 sources 只有 `CampusMatch/`），是沒有 Xcode 時用來把關的兩支檢查。需要 Swift 5.9 以上的工具鏈。

| 檢查 | 指令 | 驗證什麼 | 不能驗證什麼 |
|---|---|---|---|
| 契約測試 | `ios/Checks/contract.sh [baseURL]` | 把 App 原封不動的 `APIClient.swift`、`Models.swift` 編成命令列程式，對執行中的後端跑 21 項：50 位示範學生的 `/me`、成長、競賽推薦；案件完整生命週期（邀請 → 接受 → 開始 → 結案 → 投票 → 互評 → 結案證據）；三個 Agent；AI 助理多步驟任務、追問、確認、撤回同意。每個回應都要能解成 App 的型別，每段顯示文字都要組得出來 | SwiftUI 畫面、導覽、推播 |
| 型別檢查 | `ios/Checks/typecheck.sh` | 用 `Checks/stubs/` 的 SwiftUI／UIKit 介面樁（只有簽章、沒有實作）對 17 個原始檔做型別檢查：欄位名稱、參數標籤、Optional、async/await、主執行緒隔離 | 介面樁是依 iOS 17 SDK 手寫的，不保證與 Apple 的 SwiftUI 完全一致；`CampusMatchApp.swift`（UserNotifications、AppDelegate）不在範圍內 |

契約測試會寫入資料（新增證據、建立案件、送出邀請），請對示範資料（`APP_SEED_MODE=demo`）執行。
