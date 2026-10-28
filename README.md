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
- 科目表匯入工具：`backend/tools/fcu_curriculum.py`（fetch → parse → sql），規則表 `backend/tools/skill_rules.csv`。

## 正式上線模式（reference）與科目表
兩種啟動模式，由環境變數 `APP_SEED_MODE` 決定：

| | `demo`（預設） | `reference`（正式上線） |
|---|---|---|
| 學生資料 | 50 位示範學生、劇本案件（`db/data.sql`） | 不載入任何假資料，學生自行註冊 |
| 科目表 | 同右 | 逢甲大學 112–115 入學年度、79 個系所、約 22,000 門科目（必修／選修／校共同必修與通識），來源為註冊課務組公告（`db/ref-courses.sql`） |
| 科目→技能 | 同右 | 184 條關鍵字規則自動建議（`tools/skill_rules.csv` → `db/ref-skill-map.sql`，source=RULE）；學生自填（SELF）與 AI 建議（LLM）須由管理員核准後才計入排序 |
| 管理員 | admin@example.edu | 啟動時依 `APP_ADMIN_EMAIL`／`APP_ADMIN_PASSWORD` 建立 |
| Demo 時鐘／重置 | 允許 | `APP_DEMO_CLOCK=false` → 403 |

正式啟動範例：
```bash
APP_SEED_MODE=reference APP_RESET_ON_START=false APP_DEMO_CLOCK=false \
APP_ADMIN_EMAIL=admin@o365.fcu.edu.tw APP_ADMIN_PASSWORD='改成強密碼' APP_JWT_SECRET='改成 32 字元以上亂數' \
java -jar backend/target/campus-match-1.0.0.jar
```
`APP_RESET_ON_START=false` 時只在資料表不存在的第一次啟動建表；之後每次啟動只「補齊」參考資料（全部 `ON CONFLICT DO NOTHING`，不會覆蓋管理員改過的對照或系所名稱）。

學生端流程：註冊時填「入學學年度」（未填則由年級推算）→ 我的檔案 →「從科目清單填分數」→ 預設顯示本系該年度的 必修／選修／校共同·通識 三個分頁，點科目填分數即可（學期自動推算：入學年度＋科目年級−1）；外系選修可切換系所或「搜尋全校」。若本系尚無該年度科目表，自動顯示最接近的年度。沒有技能對照的科目可自填技能，送交管理員核准。

管理後台新增「科目表與科目→技能對照」：待核准清單（核准後立即重算相關學生的技能預設等級）、426 份科目表的覆蓋率、補登科目、修正系所名稱／學院（`PUT /admin/departments/{id}`）。

重新匯入科目表（學校每年公告新年度時）：
```bash
cd backend/tools && export SSL_CERT_FILE=/path/to/ca.pem   # 一般環境不需要
python3 fcu_curriculum.py fetch --year 116 --year 115 --year 114 --year 113 --year 112   # 下載索引頁與 PDF 到 curriculum/
python3 fcu_curriculum.py parse        # 解析兩種 PDF 版式 → curriculum/courses.csv、parse_report.csv
python3 fcu_curriculum.py sql > ../src/main/resources/db/ref-courses.sql
```
已知限制：115 起的新版 PDF 以「管理單位」取得正式系所名，少數新設學程（如「資通訊與電控產業」「人工智慧科技與管理碩士學位學程」）沿用公告上的學門名，可在後台修正；碩士班分組（財經法律、經營管理在職專班、機械與電腦輔助工程）合併為同一系所清單，組別保留在 group_code。

## 部署到 Azure（驗收後）
| 元件 | 服務 | 設定 |
|---|---|---|
| 後端 | App Service（Java 17，Linux） | 開啟 Always On（排程才會跑）；環境變數 `SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD`、`APP_JWT_SECRET`、`APP_SEED_MODE=reference`、`APP_RESET_ON_START=false`、`APP_DEMO_CLOCK=false`、`APP_ADMIN_EMAIL`、`APP_ADMIN_PASSWORD` |
| 資料庫 | Azure Database for PostgreSQL 彈性伺服器 | 允許 App Service 連線 |
| 網頁 | Static Web Apps | `cd web && VITE_API_BASE=https://<app>.azurewebsites.net npm run build`，上傳 `dist/` |
| 推播 | Key Vault 存 .p8 | 環境變數 `APNS_KEY_PATH`、`APNS_KEY_ID`、`APNS_TEAM_ID`、`APNS_SANDBOX=false`（正式）|

## 專案結構
```
backend/src/main/java/tw/edu/fcu/campus/
  common/   Db 封裝、錯誤處理、登入者
  config/   JWT、Security、Demo 時鐘、資料初始化
  user/     M1 帳號、檔案、科目表查詢（/courses）、成績→技能、得獎、統計
  cases/    M2 案件、狀態機、申請／邀請（名額鎖定）
  ranking/  M3 推薦排序引擎（純 Java）與服務
  review/   M4 結案投票、雙盲互評
  growth/   M5 成長儀表板、AI Prompt、資料分析
  admin/    M6 參數、Demo 時鐘、排程、稽核
  notify/   站內通知、APNs
web/src/views/  Login Home Cases CaseForm CaseDetail Review Profile PublicProfile Growth Admin；components/CoursePicker.vue 科目清單填分數
ios/CampusMatch/  SwiftUI 學生端（CoursePickerView 科目清單填分數）
```
