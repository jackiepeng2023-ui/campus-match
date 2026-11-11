# 第三方資源揭露表（內容草稿）

供轉填到主辦單位的官方表格。欄位名稱以官方表格為準；本頁列出本專案用到的所有第三方模型、服務、套件、資料與工具。

> 授權欄位依各專案的公告整理（整理日 2026-11-11），屬二手資訊；繳交前請逐項到官方頁面核對版本與授權。

## 1. 模型與雲端服務

| 名稱 | 提供者 | 版本／型號 | 用途 | 付費／授權 | 送出的資料 | 可否替換 |
|---|---|---|---|---|---|---|
| Claude API（Messages） | Anthropic | `claude-sonnet-5-5` | AI 助理入口：理解目標、決定工具呼叫順序、撰寫回覆 | 付費 API，依 Anthropic 商業服務條款 | 去識別化的使用者訊息與工具結果（README §17.1） | 可：環境變數換模型；不設金鑰即改用規則模式 |
| Claude API（Messages，結構化輸出） | Anthropic | `claude-haiku-5-5` | 課綱 → 技能對照；競賽簡章 → 草稿 | 同上 | 科目名稱與公開課綱節錄；管理員貼上的簡章文字。不含學生資料 | 可：不設金鑰即改用關鍵字比對 |
| Apple Push Notification service | Apple | HTTP/2 Provider API | iOS 推播（選用） | 需 Apple Developer 帳號 | 裝置 token、通知標題與內文 | 可：不設定即只用站內通知 |

沒有使用其他語言模型、向量資料庫、搜尋 API 或第三方 Agent 框架。Agent 的工具呼叫迴圈、治理機制、三個媒合 Agent 的計分都是本專案自行實作（`backend/src/main/java/tw/edu/fcu/campus/assistant/`、`agent/`、`profile/`）。

## 2. 開源套件

| 名稱 | 版本 | 授權 | 用途 | 是否修改 |
|---|---|---|---|---|
| Spring Boot（starter-web、starter-security、starter-jdbc、starter-test） | 3.3.5 | Apache-2.0 | 後端框架 | 否 |
| PostgreSQL JDBC Driver | 由 Spring Boot 3.3.5 管理的版本 | BSD-2-Clause | 資料庫連線 | 否 |
| JJWT（jjwt-api、jjwt-impl、jjwt-jackson） | 0.12.6 | Apache-2.0 | JWT 簽發與驗證 | 否 |
| springdoc-openapi-starter-webmvc-ui | 2.6.0 | Apache-2.0 | OpenAPI 文件與 Swagger UI | 否 |
| Jackson（隨 Spring Boot） | 由 Spring Boot 管理 | Apache-2.0 | JSON | 否 |
| PostgreSQL | 16 | PostgreSQL License | 資料庫 | 否 |
| Vue | ^3.5.12 | MIT | 網頁框架 | 否 |
| vue-router | ^4.4.5 | MIT | 路由 | 否 |
| Chart.js | ^4.4.4 | MIT | 圖表 | 否 |
| Vite、@vitejs/plugin-vue | ^5.4.10、^5.1.4 | MIT | 網頁建置（開發期） | 否 |
| Playwright | 測試環境安裝的版本 | Apache-2.0 | 網頁冒煙測試、截圖（開發期） | 否 |
| pdfplumber | 匯入科目表時使用 | MIT | 解析科目表 PDF（開發期） | 否 |

呼叫 Claude API 使用 JDK 內建的 `java.net.http.HttpClient`，沒有使用官方或第三方 SDK。iOS App 只使用 Apple 的系統框架（SwiftUI、Foundation、UserNotifications），沒有第三方套件。

## 3. 資料

| 資料 | 來源 | 取得方式 | 取得日期 | 內容 | 使用範圍與處理 |
|---|---|---|---|---|---|
| 科目表 | 逢甲大學註冊課務組公開的各入學學年度必修科目表／應修學分表（PDF） | `fcu_curriculum.py` 下載並解析 | 2026-10 | 112–115 入學年度、79 系所、21,968 門科目：代碼、名稱、學分、年級、必選修 | 作為學生填成績的清單；每筆保留 `source_url` |
| 課綱 | 逢甲大學課程檢索系統的公開課綱頁 | `SyllabusClient`：學生填到沒有技能對照的科目時才擷取；每次請求間隔 ≥ 0.6 秒；遇 401／403／429 即停止 | 用到時擷取；程式庫內附 16 門範例 | 課程目標與內容的節錄（≤ 1,500 字）；**不取教師聯絡資料** | 只用來把科目對到 Skill ID；節錄存在 `course_syllabus` 並保留來源網址 |
| 教師專長 | 逢甲大學 17 個系所網站的公開教師簡介頁 | 人工與程式整理 | 2026-11-11 | 305 位：姓名、職稱、系所、專長、研究方向、競賽指導經歷、個人頁與來源網址。**不含 Email、電話、分機、照片** | 教師 Agent 的推薦依據；老師可要求下架；後端拒收含聯絡方式的內容 |
| 競賽 | 各競賽官方網站或主辦、承辦單位的公告（24 筆）；獎金獵人彙整頁（4 筆） | 人工整理 | 查證日 2026-11-11 | 28 筆：名稱、主辦、類別、資格、隊伍人數、報名截止日、活動日、獎項摘要、所需技能 | 競賽 Agent 的推薦依據；每筆保留 `source_url` 與 `checked_at`；畫面標示以官方公告為準 |
| 證照對照表 | 常見證照的公開名稱與發證單位 | 人工整理 | 2026-11 | 36 張：名稱、發證單位、建議分數、對應技能 | 證照證據的預設分數與技能；分數為建議值，可在管理後台調整 |
| 技能表 | 本專案自訂 | — | — | 57 個 Skill、9 類、別名與說明 | 共用 Skill 資料庫 |
| 示範學生 | **虛構**，由 `generate_seed.py`、`history.py` 以固定亂數種子產生 | — | — | 50 位學生的成績、證據、案件與互評 | 僅供展示與測試；不對應任何真人 |

所需技能（競賽）與專長對照（教師）這兩項「對到 Skill ID」的工作，是整理資料時由語言模型（Claude）依公開文字產生，再由程式檢查格式；**沒有逐筆人工審核**。

## 4. 開發工具與 AI 協作

| 工具 | 用途 | 產出範圍 |
|---|---|---|
| Claude（Anthropic 的 AI 助理） | 程式撰寫、測試、文件、資料整理的協作 | 本專案大部分的程式碼、測試腳本、文件草稿，以及競賽與教師資料的整理，是在團隊提出需求、設計決策與審閱下由 AI 協作完成 |
| Maven、Node.js／npm、Python 3、Swift 工具鏈 | 建置與測試 | — |
| Mermaid／手排 SVG | 架構圖 | `docs/architecture.svg` |

設計決策（規格書 D1–D60）、評估機制的規則（三階門檻、證據類型、不疊加、自述與已驗證）、三個 Agent 的輸入輸出，來自團隊與指導老師的討論。

## 5. 待團隊確認

| 項目 | 說明 |
|---|---|
| 官方表格的欄位 | 本頁欄位為預想；轉填時依官方表格調整 |
| AI 協作的揭露程度 | 第 4 節的敘述請依團隊實際情況與主辦單位的規定修改 |
| 本專案自身的授權 | 尚未指定（README §20） |
| 公開教師資料的適當性 | 若程式庫要設為公開，是否保留 `ref-teachers.sql` 與 `data/teachers.json`（見自評表 R9） |
