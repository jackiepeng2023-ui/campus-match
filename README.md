# 跨系資源媒合平台（CampusMatch）

把分散的人才與合作需求，變成校園內可流動的資源。這不是公佈欄，而是一個閉環：

**技能條件 → 推薦排序 → 申請成案 → 成案追蹤 → 評價回饋 → 重新排序**

| 項目 | 內容 |
|---|---|
| 專題 | 逢甲大學 資訊工程學系學士後專班 × 精誠資訊／台灣資服科技（TIST）建教合作，題目二「跨系資源媒合平台」 |
| 版本 | 1.1（2026-11-02）：正式上線模式、逢甲正式科目表、知識圖譜與 Obsidian 匯出 |
| 規格書 | 48 項設計決策（D1–D48）、資料表、API、公式、法源：https://claude.ai/artifact/Ja2jwZXLfCqpmgcPxvpEBt |
| 訓練目標對應 | 全端系統（Spring Boot＋Vue＋SwiftUI）、資料庫設計（30 張表）、核心流程（狀態機＋排程）、資料分析（推薦品質、漏斗、技能缺口、跨學院網絡） |

---

## 目錄

1. [系統架構](#1-系統架構)
2. [功能總覽](#2-功能總覽)
3. [核心規則](#3-核心規則)
4. [資料模型](#4-資料模型)
5. [正式科目表（逢甲 112–115 入學年度）](#5-正式科目表逢甲-112115-入學年度)
6. [科目 → 技能對照](#6-科目--技能對照)
7. [成長儀表板：知識圖譜與 Obsidian 匯出](#7-成長儀表板知識圖譜與-obsidian-匯出)
8. [API 一覽](#8-api-一覽)
9. [啟動模式與環境變數](#9-啟動模式與環境變數)
10. [本機啟動](#10-本機啟動)
11. [測試](#11-測試)
12. [示範帳號與 Demo 劇本](#12-示範帳號與-demo-劇本)
13. [部署（GitHub → Azure）](#13-部署github--azure)
14. [專案結構](#14-專案結構)
15. [隱私與資料保存](#15-隱私與資料保存)
16. [已知限制與後續工作](#16-已知限制與後續工作)
17. [版本紀錄](#17-版本紀錄)

---

## 1. 系統架構

```
 iOS App（SwiftUI）──┐                         ┌── PostgreSQL 16（30 張表）
                     ├── REST /api/v1 (JWT) ──┤
 網頁（Vue 3）───────┘   Spring Boot 3         ├── 排程（每分鐘）：提醒、逾時、結案確認、自動結案、互評公開、畢業生命週期
                         ├ RankingEngine（純 Java，可單元測試）
                         ├ 狀態機（案件／申請邀請／結案投票／互評）
                         └ APNs（HTTP/2 + ES256 JWT，無第三方套件）
```

| 層 | 技術 | 目錄 | 說明 |
|---|---|---|---|
| 後端 | Spring Boot 3.3（Java 17）、Spring Security + JWT（jjwt）、NamedParameterJdbcTemplate（手寫 SQL，無 ORM）、springdoc OpenAPI | `backend/` | 6 個模組：user／cases／ranking／review／growth／admin，另有 notify、config、common |
| 資料庫 | PostgreSQL 16 | `backend/src/main/resources/db/` | `schema.sql`（建表＋參數）、`data.sql`（Demo 種子）、`ref-base.sql`（技能表）、`ref-courses.sql`（正式科目表）、`ref-skill-map.sql`（對照規則） |
| 網頁 | Vue 3 + Vite + vue-router（hash）+ Chart.js，Apple HIG 風格 | `web/` | 建置後的 `dist/` 內嵌於 jar（`static/`），單一 jar 即可服務網頁與 API |
| iOS | SwiftUI（iOS 17+）、URLSession async/await、Canvas、APNs | `ios/` | XcodeGen `project.yml`，14＋2 個 Swift 檔 |
| 工具 | Python 3 | `backend/tools/` | 種子產生器、端到端驗證、科目表匯入、對照規則表 |

架構圖：`docs/architecture.png`（Mermaid 原始檔 `docs/architecture.mmd`）。

### 1.1 設計原則

1. **一套資料結構服務兩種時間尺度**：長線（技能檔、成長紀錄、雙向搜尋）與短期（時間配合、完工評價）共用同一張技能表與同一個排序公式。
2. **誠信優先、事後檢驗**：成績與得獎由學生自填（D5），由結案互評的「相符度」（1–5）事後檢驗，分數低就調降其自填資料在排序中的權重（D7、D38）。
3. **每個數字可追溯**：推薦分數的 5 道閘門、5 個分項與理由由後端算好回傳；權重、係數、得獎矩陣、系統參數全部在資料表，管理員改了立即生效。
4. **正式資料來源**：科目表來自學校公告，不由學生自由輸入科目名稱；科目→技能對照須經核准才計入排序。

---

## 2. 功能總覽

| 角色 | 網頁 | iOS | 功能 |
|---|---|---|---|
| 學生（人才方） | ✓ | ✓ | 註冊（含入學學年度）、從本系科目清單填分數、技能自評、得獎紀錄、可投入時間、公開檔案、推薦給我的案件、申請／回覆邀請、結案投票、雙盲互評、成長儀表板（雷達、時間軸、知識圖譜、Obsidian 匯出、AI Prompt）、畢業確認、刪除帳號 |
| 學生（發案方） | ✓ | 部分 | 開案（類型、每隊人數、角色與技能條件、時數、期間、成果歸屬）、查看推薦人選與閘門原因、邀請、核准申請、開始執行、提出結案 |
| 管理員 | ✓ | — | 排序權重、可信度係數、得獎矩陣、系統參數；科目表總覽、科目→技能對照核准、補登科目、修正系所；資料分析（漏斗、推薦品質、技能缺口、跨學院網絡）；Demo 時鐘、重置；事件稽核 |
| 系統 | — | — | 每分鐘排程：到期前提醒、逾時自動放棄＋名額釋放、結案確認逾時視為同意、結束日後自動結案、互評逾時公開、畢業前 30 天提醒／去識別化／刪除；站內通知＋APNs 推播 |

案件類型：專題（PROJECT）、競賽（COMPETITION）、短期支援（SHORT_TERM）、研究協作（RESEARCH，含成果歸屬：論文掛名／致謝／無）。

---

## 3. 核心規則

### 3.1 技能等級的來源（D7、D10、D14）

| 來源 | 規則 |
|---|---|
| 成績換算（GRADE） | 科目分數依學制換算等級：學士 90→5、80→4、70→3、60→2、其餘 1；碩博士 90→5、85→4、80→3、70→2、其餘 1。一個技能的**預設等級** = 所有對應到它的科目中換算後的最高值 |
| 自評（SELF） | 學生可調整等級（上調或新增）；調整幅度記錄在 `skill_level_history`，由結案互評的相符度檢驗 |
| 結案驗證（CASE） | 案件完成後，角色所需技能的等級被標記為「結案驗證」 |

只有**已核准**的科目→技能對照（`course_skill_map.approved = true`）會換算等級。

### 3.2 推薦排序（RankingEngine，D36–D38、D41）

先過閘門，再算分數；被擋下的人選仍列出原因（「被閘門擋下」區）。

| 閘門 | 條件 |
|---|---|
| G1 身分 | 非發案方本人、非本案成員、沒有待處理的申請或邀請 |
| G2 必要技能 | 每個 `is_required` 的技能等級 ≥ `min_level`（加分技能不擋，未達標半計） |
| G3 時間 | 每週可投入時數 ≥ 角色需求，且可用期間與案件期間重疊 |
| G4 名額 | 案件在招募中且該角色尚有名額 |

$$\text{Score} = 100 \times (0.40\,S + 0.20\,T + 0.20\,R + 0.10\,P + 0.10\,C)$$

| 分項 | 計算 |
|---|---|
| S 技能符合度 | 必要技能權重 2、加分技能權重 1；等級 ÷ 5 加權平均，再 × **可信度係數** |
| T 時間配合 | min(可投入時數 ÷ 需求時數, 1) × 期間重疊比例 |
| R 評價 | 0.75 × 隊友互評（滿意度、準時、溝通平均 ÷ 5；無紀錄時冷啟動 0.5）＋ 0.25 × 得獎分（得獎矩陣累加，上限 1.0） |
| P 回應率 | 被邀請／被申請時的回應比例；逾時未回覆會降低 |
| C 跨系互補 | 跨學院 1.0、同學院不同系 0.5、同系 0 |

**可信度係數**（依歷次互評「此人實際能力與檔案相符嗎」平均）：尚無互評／4–5 → 1.0、3 → 0.8、2 → 0.6、1 → 0.4。
**得獎矩陣**：第一名 校內 0.5／全國 0.8／國際 1.0；前三名 0.4／0.65／0.8；佳作 0.25／0.4／0.5；入圍 0.15／0.25／0.3。
權重、係數、矩陣都在資料表（`ranking_weights`、`credibility_coefficients`、`award_matrix`），管理後台可調。每次查推薦會寫入 `recommendations` 快照，供事後計算 Precision@5。

### 3.3 案件與申請狀態機（D17–D25、D34）

```
案件     DRAFT → OPEN → FORMED → IN_PROGRESS → CLOSING → CLOSED
                  │        │
                  ├→ EXPIRED（截止未成案）      DRAFT／OPEN／FORMED → CANCELLED
申請／邀請  PENDING → ACCEPTED ／ DECLINED ／ WITHDRAWN ／ EXPIRED（逾時）／ FULL（額滿）
```

| 規則 | 內容 |
|---|---|
| 角色名額 | 每隊人數 N（含發案方），各角色名額總和必須等於 N − 1；同一角色同時只能有一筆 PENDING（資料庫部分唯一索引） |
| 名額鎖定 | 核准／接受時 `SELECT … FOR UPDATE` 鎖住角色列，額滿回 409 `FULL` |
| 自動成案 | 所有角色到齊 → 自動 FORMED，通知全員 |
| 回應期限 | 72 小時或截止日取較早者；到期前 24 小時提醒；逾時自動 EXPIRED、釋放名額、計入回應率 |
| 數量上限 | 每人同時開放案件（預設 3，0 = 不設限）、待處理申請（預設 5） |

### 3.4 結案與雙盲互評（D34、D35、D39、D40）

1. 發案方提出結案（完成／未完成）→ CLOSING，成員 72 小時內投票，**過半（⌊n/2⌋+1）** 通過；逾時未投視為同意；結束日後 7 天未提出則自動結案。
2. CLOSED 後建立每一對成員的互評：滿意度、準時、溝通、**相符度**（各 1–5）＋評語，72 小時內完成。
3. **雙盲**：雙方都送出後才同時公開；逾時自動公開已送出者。少於 3 人的案件只顯示累計平均，不顯示單案分數。
4. 相符度平均更新可信度係數 → 下一次排序立即反映（Demo 第 8 步：74.2 → 67.0）。

### 3.5 系統參數（`system_params`，管理後台可改）

| 鍵 | 預設 | 說明 |
|---|---|---|
| max_open_cases | 3 | 每人同時開放案件上限（0 = 不設限） |
| max_pending_applications | 5 | 每人待處理申請上限 |
| response_hours | 72 | 回應期限（小時，與截止日取較早者） |
| reminder_hours | 24 | 到期前提醒 |
| close_vote_hours | 72 | 結案確認期限 |
| review_hours | 72 | 互評期限 |
| auto_close_days | 7 | 結束日後自動結案 |
| deidentify_months | 3 | 畢業後去識別化 |
| purge_months | 6 | 畢業後刪除本人資料 |

---

## 4. 資料模型

30 張表，分 6 組（完整 DDL 見 `backend/src/main/resources/db/schema.sql`）：

| 組 | 資料表 |
|---|---|
| 參考資料 | colleges、departments、skills（54 項／9 類）、courses、course_skill_map、grade_conversion、award_matrix |
| 使用者與檔案 | users（含 entry_year、role、畢業與去識別化時間）、user_availability、user_grades、user_skills、skill_level_history、user_awards、award_skills、consents |
| 案件 | cases、case_roles、case_role_skills、engagements（申請／邀請共用，direction 區分）、case_members |
| 結案與評價 | close_requests、close_votes、reviews、recommendations（排序快照） |
| 參數 | ranking_weights、credibility_coefficients、system_params |
| 通知與稽核 | notifications、device_tokens、event_logs |

`courses` 關鍵欄位：`department_id`（NULL = 校共同必修／通識，全校共用）、`code`、`name`、`degree`（BACHELOR／MASTER／PHD）、`entry_year`（入學學年度，民國）、`requirement`（REQUIRED／ELECTIVE／GENERAL）、`group_code`（分組）、`credits`、`grade_year`、`term`、`source_url`；唯一鍵 (department_id, degree, entry_year, name)。
`course_skill_map`：`source`（ADMIN／RULE／LLM／SELF）、`confidence`、`approved`。

---

## 5. 正式科目表（逢甲 112–115 入學年度）

| 項目 | 內容 |
|---|---|
| 來源 | 逢甲大學註冊課務組各入學學年度「必修科目表／應修學分表」索引頁與 PDF（`source_url` 逐筆保留） |
| 範圍 | 112、113、114、115 入學學年度；10 個學院、79 個系所／學位學程（含學士後專班、進修學士班、雙學士學位學程、碩博士班）；約 22,000 門科目 |
| 分類 | 必修（REQUIRED）、選修（ELECTIVE）、校共同必修與通識（GENERAL；115 起為全校共用檔，之前年度列在各系科目表內） |
| 欄位 | 課程編碼、科目名稱、學分、年級、學期、分組（如碩士班組別）、學制 |
| 學生操作 | 註冊填「入學學年度」（未填由年級推算）→ 我的檔案 →「從科目清單填分數」→ 預設本系該年度的 必修／選修／校共同·通識 三個分頁，點科目填分數即可；學期自動推算（入學年度＋科目年級−1）；外系選修可切換系所或「搜尋全校」；本系尚無該年度科目表時自動顯示最接近的年度 |

### 5.1 重新匯入（學校公告新年度時）

```bash
cd backend/tools
python3 fcu_curriculum.py fetch --year 116 --year 115 --year 114 --year 113 --year 112   # 索引頁 → PDF（curriculum/pdf/，不進 git）
python3 fcu_curriculum.py parse                                                        # 兩種版式 → curriculum/courses.csv、parse_report.csv
python3 fcu_curriculum.py sql > ../src/main/resources/db/ref-courses.sql
```

解析器處理的情況：≤114 的表格版式（pdfplumber 表格、年級×上下學期）與 115 起的「課程編碼／科目名稱／學分」兩欄版式；雙語版科目名拆出代碼與中文名；115 起以 PDF 內「管理單位：學院/系所」取得正式系所名；在職專班、碩士班分組（財經法律、經營管理、機械與電腦輔助工程）依 `ALIASES` 合併為同一系所，組別保留在 `group_code`；輔系、雙主修、學分學程、微學程、英文版重複檔排除；表頭與表尾學分規定過濾。

---

## 6. 科目 → 技能對照

| 來源 | 規則 | 進入排序 |
|---|---|---|
| RULE | `backend/tools/skill_rules.csv` 264 條關鍵字規則（關鍵字、技能、信心 0–1、排除詞），啟動時由 `ref-skill-map.sql` 套用到全部科目 | 是（已核准） |
| SELF | 學生填分數時對「尚無對照」的科目自填技能（信心 0.5） | 待管理員核准 |
| LLM | 預留：AI 建議（信心由模型給） | 待管理員核准 |
| ADMIN | 管理後台手動新增／核准／退回 | 是 |

管理員核准或退回後，系統立即重算該科目所有學生的技能預設等級。對照覆蓋率（2026-11-02 實測）：

| 學院 | 必修科目有對照 | 全部科目有對照 |
|---|---|---|
| 資訊電機學院 | 93% | 69% |
| 金融學院 | 91% | 83% |
| 商學院 | 88% | 72% |
| 建設學院 | 86% | 69% |
| 建築專業學院 | 85% | 73% |
| 工程與科學學院 | 79% | 62% |
| 人文社會學院 | 70% | 57% |
| **全校** | **86%** | **68%** |

未對照的多為不對應專業技能的課（學術研究倫理教育、批判思考等）。技能表 54 項、9 類：後端、前端、資料分析、設計、簡報、商管、工程、語言、其他（`ref-base.sql`）。

---

## 7. 成長儀表板：知識圖譜與 Obsidian 匯出

成長只來自有紀錄的事：成績換算、自評調整、成案、得獎、結案互評（D30）。儀表板內容：

| 區塊 | 內容 |
|---|---|
| 知識圖譜 | 本人的 **科目（藍）→ 技能（綠）→ 分類（紫）**，加上 **得獎（橘）→ 技能**、**結案案件（灰）→ 本人角色所需技能**；力導向圖（自製，無外部套件），拖曳、縮放、點選聚焦（相鄰亮、其餘變暗、顯示明細）、依類型顯示／隱藏 |
| 技能雷達 | 9 類技能的平均等級 |
| 技能等級變化 | 每月各類別最高等級折線 |
| 成長時間軸 | 技能變動、加入／發起／結案案件、得獎、公開後的評價 |
| AI 成長建議 | 平台不串接 AI；由系統組出只含本人彙總資料的 Prompt（不含隊友姓名、評語、案件名稱），學生自行貼到 Claude／ChatGPT／Gemini／Grok／Perplexity（D31–D33） |

**匯出 Obsidian Vault**（`GET /me/growth/obsidian`，zip）：

```
成長儀表板-<姓名>/
├─ 我的成長地圖.md          索引（分類 → 技能 ★ → 來源科目）
├─ README.md               使用方式
├─ .obsidian/graph.json    Graph view 顏色預設（科目藍、技能綠、分類紫、得獎橘、案件灰）
├─ 分類/後端.md             平均等級、技能清單
├─ 技能/Python.md           等級、預設等級、來源；來源科目／得獎驗證／結案驗證
├─ 科目/資料結構.md         分數、學期、必修／選修、系所；換算成的技能
├─ 得獎/校園黑客松.md
└─ 案件/<案件名稱>.md        角色、結果、結案日；實作驗證的技能
```

每個 .md 以 `[[技能/Python|Python]]` 形式互連，frontmatter 含分數／等級／學期與 tags。解壓後在 Obsidian 選 **Open folder as vault**，Graph view 即為同一張圖；Filters 可用 `path:技能`、`tag:#後端`。iOS 以 ShareLink 分享 zip。

---

## 8. API 一覽

Base URL `/api/v1`；除註冊、登入、`/meta`、`/health` 外皆需 `Authorization: Bearer <JWT>`；`/admin/**`、`/analytics/**` 需 ADMIN。錯誤格式 `{code, message, reasons[]}`。OpenAPI：`/swagger-ui.html`。

| 模組 | 端點 |
|---|---|
| 帳號 | `POST /auth/register`（studentNo、name、email、password、degree、year、departmentId、entryYear、expectedGraduation、hoursPerWeek、consent）、`POST /auth/login`、`GET /health`、`GET /meta`（學院、系所、技能、目前學年度、案件類型、換算表、得獎矩陣） |
| 本人檔案 | `GET /me`、`PUT /me/grades`（[{courseId, score, semester?, skillIds?}]）、`DELETE /me/grades/{id}`、`PUT /me/skills`、`DELETE /me/skills/{skillId}`、`POST /me/awards`、`DELETE /me/awards/{id}`、`PUT /me/availability`、`POST /me/graduation`、`DELETE /me`、`GET /users/{id}`（公開檔案，無分數） |
| 科目表 | `GET /courses/options?departmentId&degree`（有科目表的入學年度、最接近年度）、`GET /courses?departmentId&degree&entryYear&requirement`、`GET /courses?q=關鍵字`（全校搜尋） |
| 案件 | `POST /cases`、`PUT /cases/{id}`、`GET /cases`、`GET /cases/{id}`、`POST /cases/{id}/publish`、`/cancel`、`/start`、`GET /cases/{id}/engagements` |
| 申請／邀請 | `POST /roles/{roleId}/engagements`（APPLY 或 INVITE）、`GET /me/engagements`、`POST /engagements/{id}/accept`、`/decline`、`/withdraw` |
| 推薦 | `GET /roles/{roleId}/recommendations`（分數、分項、理由、被閘門擋下清單）、`GET /me/recommended-cases` |
| 結案與互評 | `POST /cases/{id}/close-requests`、`POST /close-requests/{id}/votes`、`GET /cases/{id}/reviews/pending`、`POST /cases/{id}/reviews`、`GET /me/reviews` |
| 成長 | `GET /me/growth`、`GET /me/growth/graph`、`GET /me/growth/obsidian`（zip）、`POST /me/growth-prompt` |
| 通知 | `GET /me/notifications`、`POST /me/notifications/read-all`、`POST /me/device-tokens`（APNs） |
| 分析（ADMIN） | `GET /analytics/overview`、`/skill-gap`、`/funnel`、`/network`、`/recommendation-quality` |
| 管理（ADMIN） | `GET/PUT /admin/params`、`GET/POST /admin/clock`、`POST /admin/clock/reset`、`POST /admin/run-jobs`、`POST /admin/reset`、`GET /admin/courses/summary`、`GET /admin/course-skills?approved=false`、`PUT /admin/course-skills`、`DELETE /admin/course-skills/{courseId}/{skillId}`、`POST /admin/courses`、`PUT /admin/departments/{id}`、`GET /admin/event-logs` |

共 66 個端點。

---

## 9. 啟動模式與環境變數

| 變數 | 預設 | 說明 |
|---|---|---|
| `APP_SEED_MODE` | `demo` | `demo`：50 位示範學生＋劇本資料；`reference`：正式上線，只載入學校參考資料（科目表、技能表、對照規則），不載入任何假學生 |
| `APP_RESET_ON_START` | `true` | `true`：每次啟動重建 schema（Demo）；`false`：沿用現有資料，只在資料表不存在時初始化；每次啟動仍補齊參考資料（全部 `ON CONFLICT DO NOTHING`，不覆蓋管理員改過的對照或系所名稱） |
| `APP_DEMO_CLOCK` | `true` | 允許 `/admin/clock` 快轉與 `/admin/reset`；正式環境設 `false`（回 403） |
| `APP_ADMIN_EMAIL`／`APP_ADMIN_PASSWORD`／`APP_ADMIN_NAME` | 空 | 啟動時若此帳號不存在則建立管理員 |
| `APP_JWT_SECRET` | 內建 Demo 值 | 正式環境必改（32 字元以上亂數） |
| `APP_DEMO_PASSWORD` | `demo1234` | Demo 示範帳號密碼 |
| `SPRING_DATASOURCE_URL`／`USERNAME`／`PASSWORD` | `jdbc:postgresql://localhost:5432/campus`／`campus`／`campus` | 資料庫連線 |
| `PORT` | `8080` | HTTP 埠 |
| `APNS_KEY_PATH`／`APNS_KEY_ID`／`APNS_TEAM_ID`／`APNS_BUNDLE_ID`／`APNS_SANDBOX` | 空／`tw.edu.fcu.campusmatch`／`true` | 推播；未設定時只送站內通知 |

正式啟動範例：

```bash
APP_SEED_MODE=reference APP_RESET_ON_START=false APP_DEMO_CLOCK=false \
APP_ADMIN_EMAIL=admin@o365.fcu.edu.tw APP_ADMIN_PASSWORD='改成強密碼' APP_JWT_SECRET='改成 32 字元以上亂數' \
SPRING_DATASOURCE_URL='jdbc:postgresql://<host>:5432/campus?sslmode=require' SPRING_DATASOURCE_USERNAME=... SPRING_DATASOURCE_PASSWORD=... \
java -jar backend/target/campus-match-1.0.0.jar
```

啟動順序：`DbInit`（InitializingBean）在 Tomcat 開放連線前完成建表與載入；`GET /health` 回 `{"status":"ok","ready":true}` 後才可登入。參考資料載入約 3–5 秒。

---

## 10. 本機啟動

需要：JDK 17+、Node 20+、PostgreSQL 16（或 Docker Desktop）、Xcode 15+（iOS）。

```bash
# 1. 資料庫（擇一）
docker compose up -d                       # 或本機 PostgreSQL：建立使用者 campus／密碼 campus、資料庫 campus

# 2. 後端（第一次會下載依賴）；Demo 模式自動建表＋載入 50 位示範學生與正式科目表，示範密碼 demo1234
cd backend && ./mvnw spring-boot:run       # 或 ./mvnw -DskipTests package && java -jar target/campus-match-1.0.0.jar
#    網頁 http://localhost:8080   API 文件 /swagger-ui.html   健康檢查 /api/v1/health

# 3. 網頁開發模式（改前端時用；正式以 jar 內嵌的 dist 服務）
cd web && npm install && npm run dev       # http://localhost:5173，API 代理到 8080
npm run build && rm -rf ../backend/src/main/resources/static && cp -r dist ../backend/src/main/resources/static   # 更新 jar 內的網頁

# 4. iOS：見 ios/README.md（brew install xcodegen → xcodegen generate → 開啟 CampusMatch.xcodeproj → Run；登入頁可切換 API 伺服器）
```

---

## 11. 測試

| 測試 | 指令 | 內容 |
|---|---|---|
| 單元測試 | `cd backend && ./mvnw test` | RankingEngine 8 項：閘門、公式、可信度、得獎冷啟動、跨系、名額、期間重疊 |
| 端到端 | `python3 backend/tools/demo_e2e.py`（後端需在 localhost:8080，Demo 模式） | 8 步閉環，每步斷言：推薦名單、名額鎖定 409、自動 FORMED、G3 擋下 422、+49h 提醒、+24h 逾時與回應率、結案投票、雙盲公開 → 可信度 0.6 → 重新排序 74.2 → 67.0；另驗證 AI Prompt 不含隊友姓名、公開檔案不含成績、權限 401／403 |
| 正式模式 | `APP_SEED_MODE=reference APP_RESET_ON_START=true` 啟動 → 註冊 → `/courses/options` | 空庫初始化、建管理員、學生看到本系清單；再以 `APP_RESET_ON_START=false` 重啟確認資料保留 |
| 網頁 | Playwright（Chromium）腳本 | 登入、科目清單填分數、搜尋、註冊表單、管理後台對照核准、知識圖譜與 Vault 下載，確認無 JS 錯誤 |
| iOS | `swiftc -parse`／`-typecheck`（Linux 工具鏈） | 全部 Swift 檔語法檢查；Models 與 APIClient 型別檢查 |

---

## 12. 示範帳號與 Demo 劇本

Demo 模式（`APP_SEED_MODE=demo`）載入 50 位示範學生（學士 35、碩士 10、博士 5，固定亂數種子可重現），密碼皆 `demo1234`：

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
| admin@example.edu | 系統管理員 | 權重、參數、對照核准、Demo 時鐘、分析、重置 |

劇本（8 分鐘；`demo_e2e.py` 可自動跑一遍驗證）：

1. **student001** 發布「創業競賽需要網站 Demo」：每隊 3 人，前端 Vue≥3（必要）＋HTML/CSS≥2（加分），後端 Spring Boot≥3。
2. 「查看推薦人選」：王雅婷 94.3 第 1 名，分項 S/T/R/P/C 與理由；展開「被閘門擋下」看原因。
3. 邀請葉品妍（名額 1，再邀第二人被擋）；**student007** 接受；**student003** 申請後端；student001 核准 → 自動 **FORMED**。
4. **student008** 開研究協作（成果歸屬：致謝）→ 推薦第 1 名統計系郭昱辰，跨學院 C=1。
5. student001 開「短期 UI/UX 支援」→ 簡建宏技能符合但 G3 擋下並顯示原因；**student005** 在首頁看到「推薦給我的案件」並申請。
6. **admin** → Demo 時鐘 +49h（發案方收到「待回覆即將到期」）→ +24h（申請逾時自動 pass、名額釋放、回應率下降）；iOS 同步收到通知。
7. student001：開始執行 → 提出結案；student003、student007 同意 → **CLOSED** → 三人互評，對葉品妍相符度給 2 分；她送出前看不到任何分數（雙盲）。
8. **student004** 再開一個前端案件：葉品妍從 74.2（第 3 名）掉到 67.0（第 4 名，可信度 0.6），王雅婷維持第 1。接著看成長儀表板（知識圖譜、Obsidian 匯出）、AI Prompt、管理後台漏斗／技能缺口／跨學院網絡。

彩排之間：管理後台「重置資料」或重新啟動後端即可回到初始狀態。

---

## 13. 部署（GitHub → Azure）

| 元件 | 服務 | 設定 |
|---|---|---|
| 後端＋網頁 | App Service（Linux，Java 17，B1 以上） | 開啟 **Always On**（排程才會跑）；上傳 `campus-match-1.0.0.jar`；環境變數見第 9 節（`APP_SEED_MODE=reference`、`APP_RESET_ON_START=false`、`APP_DEMO_CLOCK=false`、`APP_ADMIN_*`、`APP_JWT_SECRET`、`SPRING_DATASOURCE_*`） |
| 資料庫 | Azure Database for PostgreSQL 彈性伺服器（B1ms 以上，PostgreSQL 16） | 允許 App Service 連線；連線字串加 `?sslmode=require`；第一次啟動由程式自動建表 |
| 推播 | Key Vault 存 APNs .p8 | `APNS_KEY_PATH`、`APNS_KEY_ID`、`APNS_TEAM_ID`、`APNS_SANDBOX=false`（正式） |
| iOS | TestFlight | `project.yml` 填 `DEVELOPMENT_TEAM`；`Info.plist` 移除 `NSAllowsArbitraryLoads`，API 改 https |

GitHub：倉庫已含 `.gitignore`（`backend/target`、`web/node_modules`、`web/dist`、`backend/tools/curriculum/pdf` 不進版控）。推送後可在 App Service 設定「部署中心」連到倉庫，或以 `az webapp deploy --src-path backend/target/campus-match-1.0.0.jar --type jar` 手動部署。

---

## 14. 專案結構

```
backend/
  src/main/java/tw/edu/fcu/campus/
    common/   Db 封裝、ApiException、GlobalExceptionHandler、Current（登入者）
    config/   DbInit（啟動模式）、JwtService／JwtFilter、SecurityConfig、DemoClock
    user/     M1 UserController／UserService（帳號、檔案、成績→技能、得獎、畢業、刪除）、CourseController（科目表查詢）、StatsService
    cases/    M2 CaseController／CaseService（案件、角色、狀態機、申請／邀請、名額鎖定、自動成案）
    ranking/  M3 RankingEngine（純 Java）、RankingService、RecommendationController
    review/   M4 ReviewController／ReviewService（結案投票、雙盲互評、逾時）
    growth/   M5 GrowthController、GrowthService（儀表板、AI Prompt、分析）、GraphService（知識圖譜、Obsidian 匯出）
    admin/    M6 AdminController（參數、對照核准、科目補登、系所修正、時鐘、重置、稽核）、SchedulerService（排程）
    notify/   NotificationService、NotificationController、ApnsSender
  src/main/resources/
    application.yml                 設定與環境變數對應
    db/schema.sql                   30 張表、權重、係數、系統參數
    db/data.sql                     Demo 種子（generate_seed.py 產生）
    db/ref-base.sql                 技能表、換算表、得獎矩陣
    db/ref-courses.sql              正式科目表（fcu_curriculum.py 產生，約 10 MB）
    db/ref-skill-map.sql            科目→技能規則（skill_rules.csv 產生）
    static/                         網頁建置結果（web/dist）
  src/test/java/tw/edu/fcu/campus/RankingEngineTest.java
  tools/
    generate_seed.py、history.py    Demo 種子與歷史紀錄產生器（固定亂數種子）
    demo_e2e.py                     端到端閉環驗證
    fcu_curriculum.py               科目表匯入：fetch → parse → sql
    skill_rules.csv                 科目→技能關鍵字規則（264 條）
    curriculum/                     index.csv、courses.csv、parse_report.csv（pdf/ 不進 git）
web/
  src/api.js（REST 客戶端、download）、store.js（狀態、標籤）、style.css（Apple HIG）
  src/views/   Login Home Cases CaseForm CaseDetail Review Profile PublicProfile Growth Admin
  src/components/  CoursePicker（科目清單填分數）、KnowledgeGraph（知識圖譜）、ScoreCard、Stars
ios/
  project.yml（XcodeGen）、README.md
  CampusMatch/  Models、APIClient、AppState、CampusMatchApp（APNs）、Components、LoginView、RootTabView、HomeView、
                NotificationsView、CasesView、CaseDetailView、ReviewView、GrowthView、KnowledgeGraphView、ProfileView、CoursePickerView
docs/           architecture.mmd／.png、growth-graph-example.png
docker-compose.yml   只跑 PostgreSQL
```

---

## 15. 隱私與資料保存

| 規則 | 實作 |
|---|---|
| 原始成績只有本人可見（D16） | `GET /users/{id}` 公開檔案只回技能等級；成績只在 `GET /me` |
| 同意條款（D26） | 註冊時勾選「媒合推薦」與「保存期限」兩項同意，寫入 `consents`（個資法第 19、20 條、第 11 條第 3 項） |
| 畢業生命週期（D27–D29） | 預計畢業日前 30 天提醒確認（已畢業／延畢／升學）；畢業後 3 個月去識別化（姓名、Email、學號置換）；6 個月刪除本人資料；去識別化的案件與評價紀錄保留供統計 |
| 刪除帳號 | `DELETE /me` 立即去識別化＋刪除 |
| AI Prompt、知識圖譜、Obsidian 匯出 | 只含本人資料；案件只到名稱與角色；不含隊友姓名與評語原文 |
| 雙盲互評 | 雙方送出後才公開；少於 3 人的案件不顯示單案分數 |
| 稽核 | 所有狀態變更寫入 `event_logs`（操作者、實體、動作、內容） |

---

## 16. 已知限制與後續工作

1. **科目表命名**：115 起部分新設學程沿用公告上的學門名（如「資通訊與電控產業」「人工智慧科技與管理碩士學位學程」）；碩士班分組合併為同一系所清單，必修／選修以先匯入者為準。上線前請在管理後台掃一遍系所名稱（`PUT /admin/departments/{id}`）。
2. **對照覆蓋率**：全校必修 86%、全部 68%；未對照的科目在圖譜中是孤立的藍點，待學生自填並核准。規則表可持續擴充。
3. **PDF 解析**：少數科目名在 PDF 儲存格被截斷（如「高等精實生産管理：理論及」），可用管理後台補登或修正。
4. **iOS 發案方功能**：開案表單、技能條件編輯、管理後台目前在網頁；App 以人才方與通知為主。
5. **推播**：需 Apple 開發者帳號（.p8 金鑰）；未設定時只有站內通知。
6. **LLM 對照建議**：資料表與核准流程已預留（source = LLM），尚未接模型。
7. **擴充性**：目前單一執行個體；排程以 `synchronized` 防重入，多執行個體部署時需改為資料庫鎖。

---

## 17. 版本紀錄

| 版本 | 日期 | 內容 |
|---|---|---|
| 1.1 | 2026-11-02 | 知識圖譜（網頁、iOS）與 Obsidian Vault 匯出；科目→技能規則擴充至 264 條；解析器過濾表頭 |
| 1.1-rc | 2026-10-28 | 正式上線模式（`APP_SEED_MODE=reference`、管理員建立、不重置啟動）；逢甲 112–115 入學年度正式科目表匯入（79 系所、約 22,000 科目）；科目清單填分數（網頁 CoursePicker、iOS CoursePickerView）；註冊入學學年度；對照核准流程與管理後台 |
| 1.0 | 2026-10-27 | Demo 版：50 位示範學生、8 步閉環劇本、網頁內嵌於 jar、iOS App、APNs、13 頁 App 簡報 |
