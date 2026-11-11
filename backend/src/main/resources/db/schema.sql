-- 跨系資源媒合平台 schema（PostgreSQL）
-- Demo 模式每次啟動會重建（app.reset-on-start=true）；逐表刪除以相容 Azure 受管 PostgreSQL（不需 schema 擁有權）
DROP TABLE IF EXISTS llm_calls CASCADE;
DROP TABLE IF EXISTS agent_actions CASCADE;
DROP TABLE IF EXISTS agent_steps CASCADE;
DROP TABLE IF EXISTS agent_messages CASCADE;
DROP TABLE IF EXISTS agent_sessions CASCADE;
DROP TABLE IF EXISTS event_logs CASCADE;
DROP TABLE IF EXISTS device_tokens CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS system_params CASCADE;
DROP TABLE IF EXISTS credibility_coefficients CASCADE;
DROP TABLE IF EXISTS ranking_weights CASCADE;
DROP TABLE IF EXISTS recommendations CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS close_votes CASCADE;
DROP TABLE IF EXISTS close_requests CASCADE;
DROP TABLE IF EXISTS case_members CASCADE;
DROP TABLE IF EXISTS engagements CASCADE;
DROP TABLE IF EXISTS case_role_skills CASCADE;
DROP TABLE IF EXISTS case_roles CASCADE;
DROP TABLE IF EXISTS cases CASCADE;
DROP TABLE IF EXISTS consents CASCADE;
DROP TABLE IF EXISTS skill_evidence CASCADE;
DROP TABLE IF EXISTS credential_skills CASCADE;
DROP TABLE IF EXISTS user_credentials CASCADE;
DROP TABLE IF EXISTS award_skills CASCADE;
DROP TABLE IF EXISTS user_awards CASCADE;
DROP TABLE IF EXISTS skill_level_history CASCADE;
DROP TABLE IF EXISTS user_skills CASCADE;
DROP TABLE IF EXISTS user_grades CASCADE;
DROP TABLE IF EXISTS user_availability CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS teacher_skills CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;
DROP TABLE IF EXISTS competition_skills CASCADE;
DROP TABLE IF EXISTS competitions CASCADE;
DROP TABLE IF EXISTS certificate_catalog_skills CASCADE;
DROP TABLE IF EXISTS certificate_catalog CASCADE;
DROP TABLE IF EXISTS level_bands CASCADE;
DROP TABLE IF EXISTS award_matrix CASCADE;
DROP TABLE IF EXISTS grade_conversion CASCADE;
DROP TABLE IF EXISTS course_syllabus CASCADE;
DROP TABLE IF EXISTS course_skill_map CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS colleges CASCADE;

-- ===== 參考資料 =====
CREATE TABLE colleges (id SERIAL PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE departments (id SERIAL PRIMARY KEY, college_id INT NOT NULL REFERENCES colleges(id), name VARCHAR(50) UNIQUE NOT NULL);
-- 共用 Skill 資料庫：學生、教師、競賽、案件角色都參照同一個 skill id；description／aliases 供 AI 對照（課綱、教師專長、競賽簡章 → Skill ID）
CREATE TABLE skills (id SERIAL PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL, category VARCHAR(20) NOT NULL,
  description VARCHAR(200) NOT NULL DEFAULT '', aliases VARCHAR(300) NOT NULL DEFAULT '');
-- 正式科目表：每個入學學年度 × 系所 × 學制一份；department_id NULL = 校共同必修／通識（全校共用）
CREATE TABLE courses (
  id SERIAL PRIMARY KEY,
  department_id INT REFERENCES departments(id),
  code VARCHAR(16),
  name VARCHAR(120) NOT NULL,
  degree VARCHAR(10) NOT NULL DEFAULT 'BACHELOR' CHECK (degree IN ('BACHELOR','MASTER','PHD')),
  entry_year SMALLINT,                                   -- 入學學年度；NULL = 不分年度（Demo 資料）
  requirement VARCHAR(10) NOT NULL DEFAULT 'ELECTIVE' CHECK (requirement IN ('REQUIRED','ELECTIVE','GENERAL')),
  group_code VARCHAR(20),
  credits NUMERIC(3,1),
  grade_year SMALLINT,
  term SMALLINT,
  is_graduate BOOLEAN NOT NULL DEFAULT FALSE,
  source_url TEXT,
  UNIQUE NULLS NOT DISTINCT (department_id, degree, entry_year, name));
CREATE INDEX idx_courses_lookup ON courses (department_id, degree, entry_year, requirement);
-- 科目 → 技能對照：ADMIN 人工、RULE 關鍵字規則、LLM 建議（待核准）、SELF 學生自填；只有 approved 的對照會換算技能等級
CREATE TABLE course_skill_map (
  course_id INT REFERENCES courses(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id),
  source VARCHAR(10) NOT NULL DEFAULT 'ADMIN' CHECK (source IN ('ADMIN','RULE','LLM','SELF')),
  confidence NUMERIC(3,2) NOT NULL DEFAULT 1.0, approved BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (course_id, skill_id));
-- 課綱（由 tools/fcu_syllabus.py 擷取，AI 對照 Skill 時的依據）
CREATE TABLE course_syllabus (id SERIAL PRIMARY KEY, course_name VARCHAR(120) NOT NULL, department VARCHAR(50), year SMALLINT, sms SMALLINT,
  text TEXT NOT NULL, source_url TEXT, fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE NULLS NOT DISTINCT (course_name, department));
-- D53 等級三階（取代 D14 的 1–5 級）：依證據分數推估；門檻可由管理員修改
CREATE TABLE level_bands (degree_group VARCHAR(10) NOT NULL, tier SMALLINT NOT NULL CHECK (tier BETWEEN 1 AND 3), name VARCHAR(10) NOT NULL,
  min_score SMALLINT NOT NULL CHECK (min_score BETWEEN 1 AND 100), PRIMARY KEY (degree_group, tier));
-- 證照對照表（管理員維護）：命中時證據分數由對照表決定
CREATE TABLE certificate_catalog (id SERIAL PRIMARY KEY, name VARCHAR(120) UNIQUE NOT NULL, issuer VARCHAR(80), score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 100), note VARCHAR(200) NOT NULL DEFAULT '');
CREATE TABLE certificate_catalog_skills (catalog_id INT REFERENCES certificate_catalog(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id), PRIMARY KEY (catalog_id, skill_id));
-- D41 得獎矩陣
CREATE TABLE award_matrix (rank VARCHAR(12) NOT NULL, level VARCHAR(15) NOT NULL, score NUMERIC(3,2) NOT NULL, PRIMARY KEY (rank, level));

-- ===== 使用者與學生檔案 =====
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  student_no VARCHAR(40) UNIQUE NOT NULL,
  name VARCHAR(30) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  degree VARCHAR(10) NOT NULL CHECK (degree IN ('BACHELOR','MASTER','PHD')),
  year SMALLINT NOT NULL,
  department_id INT NOT NULL REFERENCES departments(id),
  entry_year SMALLINT,                                   -- 入學學年度（民國），決定適用的科目表
  expected_graduation DATE NOT NULL,
  role VARCHAR(10) NOT NULL DEFAULT 'STUDENT' CHECK (role IN ('STUDENT','ADMIN')),
  demo_tag VARCHAR(30),
  grad_reminded_at TIMESTAMPTZ,
  deidentified_at TIMESTAMPTZ,            -- D27 去識別化時間
  purged_at TIMESTAMPTZ,                  -- D28 個人資料刪除時間
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE user_availability (user_id INT PRIMARY KEY REFERENCES users(id), hours_per_week SMALLINT NOT NULL,
  available_from DATE NOT NULL, available_to DATE NOT NULL);
-- D16 原始成績：只有本人可讀
CREATE TABLE user_grades (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), course_id INT NOT NULL REFERENCES courses(id),
  score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 100), semester VARCHAR(6) NOT NULL, UNIQUE (user_id, course_id));
-- Skill Profile（能力盤點模組的產出，由 skill_evidence 依統一規則彙整；不直接編輯）
CREATE TABLE user_skills (user_id INT REFERENCES users(id), skill_id INT REFERENCES skills(id),
  score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 100),          -- 同一技能多筆證據不疊加：取最高分
  level SMALLINT NOT NULL CHECK (level BETWEEN 0 AND 3),            -- 0 未達、1 初階、2 中階、3 進階（level_bands）
  verified_score SMALLINT,                                          -- 已驗證證據的最高分；NULL = 沒有已驗證的證據
  trust VARCHAR(8) NOT NULL DEFAULT 'SELF' CHECK (trust IN ('VERIFIED','COURSE','SELF')),   -- 目前階級的可信狀態：已驗證／修課成績／自述
  self_declared BOOLEAN NOT NULL DEFAULT TRUE,                      -- trust = 'SELF'：目前階級靠尚未驗證的自述證據
  evidence_count SMALLINT NOT NULL DEFAULT 0, source VARCHAR(12) NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, skill_id));
-- D30 技能分數歷史（成長儀表板）
CREATE TABLE skill_level_history (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), skill_id INT NOT NULL REFERENCES skills(id),
  old_score SMALLINT, new_score SMALLINT NOT NULL, reason VARCHAR(20) NOT NULL, changed_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE user_awards (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), competition VARCHAR(100) NOT NULL,
  level VARCHAR(15) NOT NULL, rank VARCHAR(12) NOT NULL, award_date DATE NOT NULL,
  proof_url TEXT, verified BOOLEAN NOT NULL DEFAULT FALSE, verified_by INT REFERENCES users(id), verified_at TIMESTAMPTZ,
  FOREIGN KEY (rank, level) REFERENCES award_matrix(rank, level));
CREATE TABLE award_skills (award_id INT REFERENCES user_awards(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id), PRIMARY KEY (award_id, skill_id));
-- 學生自填的證照、作品集、自我評估：自述；可附證明；經審核 → 已驗證
CREATE TABLE user_credentials (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id),
  type VARCHAR(12) NOT NULL CHECK (type IN ('CERTIFICATE','PORTFOLIO','SELF')),
  title VARCHAR(120) NOT NULL, issuer VARCHAR(80), obtained_on DATE, catalog_id INT REFERENCES certificate_catalog(id),
  claimed_score SMALLINT NOT NULL CHECK (claimed_score BETWEEN 0 AND 100), proof_url TEXT, note VARCHAR(300),
  verified BOOLEAN NOT NULL DEFAULT FALSE, verified_by INT REFERENCES users(id), verified_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE credential_skills (credential_id INT REFERENCES user_credentials(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id), PRIMARY KEY (credential_id, skill_id));
-- 能力盤點：每一筆「技能 × 證據」。全部保留、不疊加；由 SkillProfileService.rebuild 產生
CREATE TABLE skill_evidence (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), skill_id INT NOT NULL REFERENCES skills(id),
  type VARCHAR(12) NOT NULL CHECK (type IN ('COURSE','CERTIFICATE','PORTFOLIO','COMPETITION','CASE','SELF')),
  ref_id INT, title VARCHAR(200) NOT NULL, score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 100),
  verified BOOLEAN NOT NULL DEFAULT FALSE, proof_url TEXT, occurred_on DATE, detail VARCHAR(200) NOT NULL DEFAULT '');
CREATE INDEX idx_evidence_user ON skill_evidence (user_id, skill_id);
-- D26 同意紀錄
CREATE TABLE consents (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), purpose VARCHAR(30) NOT NULL,
  terms_version VARCHAR(10) NOT NULL, agreed_at TIMESTAMPTZ NOT NULL DEFAULT now());

-- ===== 競賽與教師（三個媒合 Agent 的資料；皆參照 skills） =====
CREATE TABLE competitions (id SERIAL PRIMARY KEY, name VARCHAR(160) UNIQUE NOT NULL, short_name VARCHAR(60), organizer VARCHAR(200),
  category VARCHAR(20) NOT NULL, level VARCHAR(15) NOT NULL CHECK (level IN ('CAMPUS','NATIONAL','INTERNATIONAL')),
  url TEXT, description VARCHAR(600) NOT NULL DEFAULT '',
  eligible_degrees VARCHAR(40) NOT NULL DEFAULT 'BACHELOR,MASTER,PHD', eligibility_note VARCHAR(300) NOT NULL DEFAULT '',
  team_min SMALLINT, team_max SMALLINT, advisor_required BOOLEAN,
  apply_deadline DATE, event_date DATE, schedule_note VARCHAR(200) NOT NULL DEFAULT '', prize VARCHAR(300),
  source VARCHAR(10) NOT NULL DEFAULT 'MANUAL' CHECK (source IN ('MANUAL','SEED','LLM')), source_url TEXT, checked_at DATE,
  approved BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE competition_skills (competition_id INT REFERENCES competitions(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id),
  min_level SMALLINT NOT NULL CHECK (min_level BETWEEN 1 AND 3),
  importance VARCHAR(8) NOT NULL DEFAULT 'CORE' CHECK (importance IN ('CORE','SUPPORT')), PRIMARY KEY (competition_id, skill_id));
-- 教師：只存系所網站公開的姓名、職稱、專長、研究方向、指導競賽經歷與來源連結；不存聯絡方式
CREATE TABLE teachers (id SERIAL PRIMARY KEY, name VARCHAR(40) NOT NULL, title VARCHAR(60), department_id INT REFERENCES departments(id),
  expertise TEXT NOT NULL DEFAULT '', research TEXT NOT NULL DEFAULT '', coaching TEXT NOT NULL DEFAULT '',
  profile_url TEXT, source_url TEXT, crawled_at DATE, active BOOLEAN NOT NULL DEFAULT TRUE, UNIQUE (name, department_id));
CREATE TABLE teacher_skills (teacher_id INT REFERENCES teachers(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id),
  confidence NUMERIC(3,2) NOT NULL DEFAULT 0.8, source VARCHAR(10) NOT NULL DEFAULT 'LLM' CHECK (source IN ('ADMIN','RULE','LLM')),
  approved BOOLEAN NOT NULL DEFAULT TRUE, PRIMARY KEY (teacher_id, skill_id));

-- ===== 案件 =====
CREATE TABLE cases (
  id SERIAL PRIMARY KEY,
  owner_id INT NOT NULL REFERENCES users(id),
  title VARCHAR(120) NOT NULL,
  type VARCHAR(12) NOT NULL CHECK (type IN ('PROJECT','COMPETITION','SHORT_TERM','RESEARCH')),
  description TEXT NOT NULL DEFAULT '',
  team_size SMALLINT NOT NULL CHECK (team_size >= 2),           -- N（含發案方）
  apply_deadline TIMESTAMPTZ NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  attribution VARCHAR(12) CHECK (attribution IN ('AUTHORSHIP','ACK','NONE')),  -- D13 研究協作必填
  status VARCHAR(12) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','OPEN','FORMED','IN_PROGRESS','CLOSING','CLOSED','CANCELLED','EXPIRED')),
  close_result VARCHAR(12) CHECK (close_result IN ('COMPLETED','INCOMPLETE')),
  competition_id INT REFERENCES competitions(id),               -- 競賽隊伍：由競賽 Agent 的推薦開案
  advisor_teacher_id INT REFERENCES teachers(id),               -- 隊伍選定的指導老師（教師 Agent 推薦；需自行向老師確認）
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at TIMESTAMPTZ,
  CHECK (type <> 'RESEARCH' OR attribution IS NOT NULL));
CREATE TABLE case_roles (id SERIAL PRIMARY KEY, case_id INT NOT NULL REFERENCES cases(id), role_name VARCHAR(40) NOT NULL,
  headcount SMALLINT NOT NULL CHECK (headcount >= 1), filled_count SMALLINT NOT NULL DEFAULT 0,
  hours_per_week SMALLINT NOT NULL DEFAULT 4, CHECK (filled_count <= headcount));
CREATE TABLE case_role_skills (case_role_id INT REFERENCES case_roles(id), skill_id INT REFERENCES skills(id),
  min_level SMALLINT NOT NULL CHECK (min_level BETWEEN 1 AND 3), is_required BOOLEAN NOT NULL DEFAULT TRUE,   -- 1 初階、2 中階、3 進階
  PRIMARY KEY (case_role_id, skill_id));
-- D17 申請與邀請共用：direction 區分
CREATE TABLE engagements (
  id SERIAL PRIMARY KEY,
  case_role_id INT NOT NULL REFERENCES case_roles(id),
  user_id INT NOT NULL REFERENCES users(id),           -- 加入角色的人
  direction VARCHAR(6) NOT NULL CHECK (direction IN ('APPLY','INVITE')),
  status VARCHAR(10) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING','ACCEPTED','DECLINED','WITHDRAWN','EXPIRED','FULL')),
  message VARCHAR(300) NOT NULL DEFAULT '',
  score_snapshot NUMERIC(5,1),
  due_at TIMESTAMPTZ NOT NULL,
  reminded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  decided_at TIMESTAMPTZ);
CREATE UNIQUE INDEX uq_engagement_pending ON engagements (case_role_id, user_id) WHERE status = 'PENDING';
CREATE TABLE case_members (case_id INT REFERENCES cases(id), user_id INT REFERENCES users(id), case_role_id INT REFERENCES case_roles(id),
  is_owner BOOLEAN NOT NULL DEFAULT FALSE, joined_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (case_id, user_id));
-- D34 結案
CREATE TABLE close_requests (id SERIAL PRIMARY KEY, case_id INT NOT NULL REFERENCES cases(id),
  result VARCHAR(12) NOT NULL CHECK (result IN ('COMPLETED','INCOMPLETE')), auto BOOLEAN NOT NULL DEFAULT FALSE,
  status VARCHAR(10) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','PASSED','REJECTED')),
  requested_at TIMESTAMPTZ NOT NULL, due_at TIMESTAMPTZ NOT NULL, decided_at TIMESTAMPTZ);
CREATE TABLE close_votes (close_request_id INT REFERENCES close_requests(id), user_id INT REFERENCES users(id),
  agree BOOLEAN NOT NULL, voted_at TIMESTAMPTZ NOT NULL, PRIMARY KEY (close_request_id, user_id));
-- D39、D40 互評：結案時為每一對成員建立一列，送出時填分數
CREATE TABLE reviews (
  id SERIAL PRIMARY KEY,
  case_id INT NOT NULL REFERENCES cases(id),
  reviewer_id INT NOT NULL REFERENCES users(id),
  reviewee_id INT NOT NULL REFERENCES users(id),
  satisfaction SMALLINT CHECK (satisfaction BETWEEN 1 AND 5),
  match_score SMALLINT CHECK (match_score BETWEEN 1 AND 5),
  on_time SMALLINT CHECK (on_time BETWEEN 1 AND 5),
  communication SMALLINT CHECK (communication BETWEEN 1 AND 5),
  attribution_kept VARCHAR(8) CHECK (attribution_kept IN ('YES','PARTIAL','NO')),
  comment VARCHAR(500),
  due_at TIMESTAMPTZ NOT NULL,
  submitted_at TIMESTAMPTZ,
  revealed_at TIMESTAMPTZ,
  missed BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (case_id, reviewer_id, reviewee_id));
-- 推薦快照（推薦理由與分析）
CREATE TABLE recommendations (id SERIAL PRIMARY KEY, case_role_id INT NOT NULL REFERENCES case_roles(id), user_id INT NOT NULL REFERENCES users(id),
  rank SMALLINT NOT NULL, score NUMERIC(5,1) NOT NULL, breakdown_json JSONB NOT NULL, generated_at TIMESTAMPTZ NOT NULL);

-- ===== 參數、通知、紀錄 =====
CREATE TABLE ranking_weights (key VARCHAR(20) PRIMARY KEY, value NUMERIC(4,2) NOT NULL, label VARCHAR(30) NOT NULL);
CREATE TABLE credibility_coefficients (match_level SMALLINT PRIMARY KEY, coefficient NUMERIC(3,2) NOT NULL);
CREATE TABLE system_params (key VARCHAR(40) PRIMARY KEY, value INT NOT NULL, label VARCHAR(60) NOT NULL);
CREATE TABLE notifications (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), type VARCHAR(20) NOT NULL,
  title VARCHAR(100) NOT NULL, body VARCHAR(300) NOT NULL DEFAULT '', link VARCHAR(100), created_at TIMESTAMPTZ NOT NULL, read_at TIMESTAMPTZ);
CREATE TABLE device_tokens (user_id INT REFERENCES users(id), token VARCHAR(200) NOT NULL, platform VARCHAR(10) NOT NULL DEFAULT 'ios',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, token));
CREATE TABLE event_logs (id SERIAL PRIMARY KEY, actor_id INT, entity VARCHAR(20) NOT NULL, entity_id INT, action VARCHAR(30) NOT NULL,
  payload JSONB, created_at TIMESTAMPTZ NOT NULL);

-- ===== AI 助理（入口 Agent）：對話、工具呼叫軌跡、待確認動作、LLM 用量 =====
CREATE TABLE agent_sessions (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), title VARCHAR(80) NOT NULL DEFAULT '',
  aliases JSONB NOT NULL DEFAULT '{}',          -- 送給語言模型的學生代號（S1、S2…）→ user_id；姓名只在伺服器端還原
  state JSONB NOT NULL DEFAULT '{}',            -- 對話脈絡：最近談到的競賽、推薦過的隊友與老師（規則模式與待確認動作使用）
  created_at TIMESTAMPTZ NOT NULL, updated_at TIMESTAMPTZ NOT NULL);
CREATE TABLE agent_messages (id SERIAL PRIMARY KEY, session_id INT NOT NULL REFERENCES agent_sessions(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL CHECK (role IN ('user','assistant')), content TEXT NOT NULL, mode VARCHAR(10),
  status VARCHAR(10) NOT NULL DEFAULT 'DONE' CHECK (status IN ('RUNNING','DONE','ERROR')),   -- 助理回覆在背景執行，前端輪詢顯示工具呼叫軌跡
  notice VARCHAR(300),                          -- 降級說明（未同意、未設定金鑰、API 失敗 → 規則模式）
  cards JSONB, api_content JSONB,
  -- 評測指標（決賽要求：成功率、延遲、成本、工具調用成功率、重試、人工介入、中止、錯誤分類）
  stop VARCHAR(20),                             -- END_TURN 正常完成｜RULE 規則模式｜FALLBACK API 失敗後改規則｜MAX_STEPS 達工具呼叫上限而中止｜MAX_TOKENS｜REFUSAL｜ERROR
  duration_ms INT NOT NULL DEFAULT 0, llm_calls SMALLINT NOT NULL DEFAULT 0, llm_retries SMALLINT NOT NULL DEFAULT 0,
  input_tokens INT NOT NULL DEFAULT 0, output_tokens INT NOT NULL DEFAULT 0,
  tool_calls SMALLINT NOT NULL DEFAULT 0, tool_errors SMALLINT NOT NULL DEFAULT 0,
  checks JSONB,                                 -- 輸出檢核：回覆中的分數、日期、學生代號是否都能對應到工具結果
  feedback SMALLINT, feedback_note VARCHAR(300),  -- 使用者回饋：1 有幫助、-1 沒幫助
  created_at TIMESTAMPTZ NOT NULL);
CREATE TABLE agent_steps (id SERIAL PRIMARY KEY, session_id INT NOT NULL REFERENCES agent_sessions(id) ON DELETE CASCADE, message_id INT,
  seq SMALLINT NOT NULL, agent VARCHAR(20) NOT NULL, tool VARCHAR(40) NOT NULL, input JSONB, summary VARCHAR(400) NOT NULL DEFAULT '',
  output JSONB,                                 -- 交給語言模型的工具結果（學生以代號表示，沒有姓名與分數）；供操作軌跡查核
  ok BOOLEAN NOT NULL DEFAULT TRUE, duration_ms INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL);
CREATE TABLE agent_actions (id SERIAL PRIMARY KEY, session_id INT REFERENCES agent_sessions(id) ON DELETE CASCADE, user_id INT NOT NULL REFERENCES users(id),
  type VARCHAR(30) NOT NULL, title VARCHAR(200) NOT NULL, payload JSONB NOT NULL,
  status VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','DONE','CANCELLED','FAILED')), result JSONB,
  created_at TIMESTAMPTZ NOT NULL, decided_at TIMESTAMPTZ);
CREATE TABLE llm_calls (id SERIAL PRIMARY KEY, purpose VARCHAR(30) NOT NULL, model VARCHAR(40), user_id INT,   -- 只記用量與狀態，不記內容
  input_tokens INT NOT NULL DEFAULT 0, output_tokens INT NOT NULL DEFAULT 0, duration_ms INT NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL, error VARCHAR(300), created_at TIMESTAMPTZ NOT NULL);

INSERT INTO ranking_weights VALUES ('S', 0.40, '技能符合度'), ('T', 0.20, '時間配合'), ('R', 0.20, '評價'), ('P', 0.10, '回應率'), ('C', 0.10, '跨系互補');
INSERT INTO credibility_coefficients VALUES (0, 1.00), (5, 1.00), (4, 1.00), (3, 0.80), (2, 0.60), (1, 0.40);
INSERT INTO system_params VALUES
  ('max_open_cases', 3, '每人同時開放案件上限（0 = 不設限）'),
  ('max_pending_applications', 5, '每人待處理申請上限'),
  ('response_hours', 72, '回應期限（小時，與截止日取較早者）'),
  ('reminder_hours', 24, '到期前提醒（小時）'),
  ('close_vote_hours', 72, '結案確認期限（小時）'),
  ('review_hours', 72, '互評期限（小時）'),
  ('auto_close_days', 7, '結束日後自動結案（天）'),
  ('deidentify_months', 3, '畢業後去識別化（月）'),
  ('purge_months', 6, '畢業後刪除（月）'),
  ('self_declared_cap', 100, '自述證據（未驗證的證照、作品集、得獎、自評）的分數上限（100 = 不封頂；84 = 最高到中階）'),
  ('course_grade_verified', 0, '課程成績是否視為已驗證（0 否：誠信自填；1 是：已對接成績單）'),
  ('max_skills_per_evidence', 5, '每筆證據（課程、證照、作品、競賽）最多對應的技能數'),
  ('llm_auto_approve_pct', 80, 'AI 對照的信心達此百分比自動生效，未達者待管理員核准'),
  ('case_evidence_min_match_x10', 30, '結案證據：隊友相符度平均達此值（×10）才產生已驗證證據'),
  ('case_confirm_match_x10', 40, '結案證據：相符度達此值（×10）時，自述分數視為已被驗證'),
  ('assistant_max_steps', 8, 'AI 助理單次回覆最多幾輪工具呼叫（超過即中止並回報）'),
  ('assistant_daily_limit', 60, 'AI 助理每人每日訊息上限（成本與濫用控管）');
-- BACHELOR＝共同量尺（教師討論表：初階 60–70、中階 70–85、進階 85–100，可修改）；GRADUATE＝研究所修課成績的門檻（及格 70），成績先換算到共同量尺
INSERT INTO level_bands VALUES ('BACHELOR', 1, '初階', 60), ('BACHELOR', 2, '中階', 70), ('BACHELOR', 3, '進階', 85),
                               ('GRADUATE', 1, '初階', 70), ('GRADUATE', 2, '中階', 80), ('GRADUATE', 3, '進階', 90);
