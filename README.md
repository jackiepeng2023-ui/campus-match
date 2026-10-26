# 跨系資源媒合平台（CampusMatch）

把分散的人才與合作需求，變成校園內可流動的資源。驗收閉環：**技能條件 → 推薦排序 → 申請成案 → 成案追蹤 → 評價回饋 → 重新排序**。

| 層 | 技術 | 目錄 |
|---|---|---|
| 後端 + 排程 | Spring Boot 3（Java 17）、Spring Security JWT、JdbcTemplate | `backend/` |
| 資料庫 | PostgreSQL 16（30 張表，啟動時自動重建並載入 50 位示範學生） | `backend/src/main/resources/db/` |
| 網頁 | Vue 3 + Vite + Chart.js（Apple HIG 風格） | `web/` |
| iOS | SwiftUI（iOS 17+），APNs 推播 | `ios/` |
| 規格書 | 48 項決策、資料表、API、公式、法源 | https://claude.ai/artifact/Ja2jwZXLfCqpmgcPxvpEBt |

## 本機啟動（Mac）

需要：Docker Desktop（或本機 PostgreSQL 16）、JDK 17+、Node 20+、Xcode 15+。

```bash
# 1. 資料庫
docker compose up -d

# 2. 後端（第一次會下載依賴，約 2–3 分鐘）；啟動時自動建表＋載入種子資料，示範密碼 demo1234
cd backend && ./mvnw spring-boot:run
#    API 文件：http://localhost:8080/swagger-ui.html   健康檢查：http://localhost:8080/api/v1/health

# 3. 網頁
cd web && npm install && npm run dev        # http://localhost:5173

# 4. iOS：見 ios/README.md（xcodegen generate → Run，模擬器直接連 localhost:8080）
```

本機 PostgreSQL 而非 Docker：建立 `campus` 使用者（密碼 `campus`，需 CREATEDB／schema owner）與 `campus` 資料庫，或用環境變數 `SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD` 覆寫。

## 示範帳號（密碼皆 demo1234）

| 帳號 | 身分 | 劇本用途 |
|---|---|---|
| student001@example.edu | 江筱涵，企管三 | 發案方：「創業競賽需要網站 Demo」 |
| student002@example.edu | 王雅婷，資工三 | Vue 5 級、有好評，推薦第 1 名 |
| student003@example.edu | 葉宇翔，資工四 | Spring Boot 強、全國程式競賽第一名 |
| student004@example.edu | 郭昱辰，統計三 | 「專題缺資料視覺化夥伴」，跨學院加分 |
| student005@example.edu | 王子軒，創設二 | 「短期 UI/UX 支援」人選 |
| student006@example.edu | 簡建宏，創設四 | 技能符合但每週只有 2 小時 → 被時間閘門擋下 |
| student007@example.edu | 葉品妍，資工二 | Vue 成績換算 3 級、自評上調到 5 級 → 結案後可信度下降 |
| student008@example.edu | 蕭婉婷，資工博三 | 研究協作發案方 |
| admin@example.edu | 系統管理員 | 權重、參數、Demo 時鐘、分析、重置 |

## Demo 劇本（8 分鐘，`backend/tools/demo_e2e.py` 可自動跑一遍驗證）

1. **student001** 發布「創業競賽需要網站 Demo」：每隊 3 人，前端 Vue≥3（必要）＋HTML/CSS≥2（加分），後端 Spring Boot≥3。
2. 點「查看推薦人選」：王雅婷 94.3 第 1 名，分項 S/T/R/P/C 與理由；展開「被閘門擋下」看原因。
3. 邀請葉品妍（名額 1，再邀第二人會被 D25 擋）；**student007** 接受；**student003** 申請後端；student001 核准 → 自動 **FORMED**。
4. **student008** 開研究協作（成果歸屬：致謝）→ 推薦第 1 名統計系郭昱辰，跨學院 C=1。
5. student001 開「短期 UI/UX 支援」→ 簡建宏技能符合但 G3 時間閘門擋下並顯示原因；**student005** 在首頁看到「推薦給我的案件」並申請。
6. **admin** → 管理 → Demo 時鐘 +49h（發案方收到「待回覆即將到期」提醒）→ +24h（申請逾時自動 pass、名額釋放、回應率下降）。iOS 上同時收到通知。
7. student001：開始執行 → 提出結案；student003、student007 同意 → **CLOSED** → 三人互評，對葉品妍相符度給 2 分；她自己送出前看不到任何分數（雙盲）。
8. **student004** 再開一個前端案件：同樣條件下葉品妍從 74.2（第 3 名）掉到 67.0（第 4 名，可信度 0.6），王雅婷維持第 1。接著看成長儀表板、AI Prompt、管理後台漏斗／技能缺口／跨學院網絡。

彩排之間：管理後台「重置資料」或重新啟動後端即可回到初始狀態。

## 測試與文件
- `cd backend && ./mvnw test`：推薦排序引擎單元測試（8 項：閘門、公式、可信度、得獎冷啟動、跨系、名額）。
- `python3 backend/tools/demo_e2e.py`：端到端跑完閉環並斷言每一步結果（後端需在 localhost:8080）。
- OpenAPI：http://localhost:8080/swagger-ui.html（36 支端點，依 6 個模組分組）。
- 種子資料產生器：`backend/tools/generate_seed.py`（固定亂數種子，可重現）。

## 部署到 Azure（驗收後）
| 元件 | 服務 | 設定 |
|---|---|---|
| 後端 | App Service（Java 17，Linux） | 開啟 Always On（排程才會跑）；環境變數 `SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD`、`APP_JWT_SECRET`、`APP_RESET_ON_START=false`（第一次 true 建表後改 false） |
| 資料庫 | Azure Database for PostgreSQL 彈性伺服器 | 允許 App Service 連線 |
| 網頁 | Static Web Apps | `cd web && VITE_API_BASE=https://<app>.azurewebsites.net npm run build`，上傳 `dist/` |
| 推播 | Key Vault 存 .p8 | 環境變數 `APNS_KEY_PATH`、`APNS_KEY_ID`、`APNS_TEAM_ID`、`APNS_SANDBOX=false`（正式）|

## 專案結構
```
backend/src/main/java/tw/edu/fcu/campus/
  common/   Db 封裝、錯誤處理、登入者
  config/   JWT、Security、Demo 時鐘、資料初始化
  user/     M1 帳號、檔案、成績→技能、得獎、統計
  cases/    M2 案件、狀態機、申請／邀請（名額鎖定）
  ranking/  M3 推薦排序引擎（純 Java）與服務
  review/   M4 結案投票、雙盲互評
  growth/   M5 成長儀表板、AI Prompt、資料分析
  admin/    M6 參數、Demo 時鐘、排程、稽核
  notify/   站內通知、APNs
web/src/views/  Login Home Cases CaseForm CaseDetail Review Profile PublicProfile Growth Admin
ios/CampusMatch/  SwiftUI 學生端
```
