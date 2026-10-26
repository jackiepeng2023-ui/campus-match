-- 跨系資源媒合平台 schema（PostgreSQL）
-- Demo 模式每次啟動會重建（app.reset-on-start=true）
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- ===== 參考資料 =====
CREATE TABLE colleges (id SERIAL PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE departments (id SERIAL PRIMARY KEY, college_id INT NOT NULL REFERENCES colleges(id), name VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE skills (id SERIAL PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL, category VARCHAR(20) NOT NULL);
CREATE TABLE courses (id SERIAL PRIMARY KEY, department_id INT REFERENCES departments(id), name VARCHAR(80) NOT NULL,
  is_graduate BOOLEAN NOT NULL DEFAULT FALSE, UNIQUE (department_id, name));
CREATE TABLE course_skill_map (course_id INT REFERENCES courses(id), skill_id INT REFERENCES skills(id), PRIMARY KEY (course_id, skill_id));
-- D14 學制換算表
CREATE TABLE grade_conversion (degree_group VARCHAR(10) NOT NULL, min_score INT NOT NULL, level SMALLINT NOT NULL, PRIMARY KEY (degree_group, min_score));
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
CREATE TABLE user_skills (user_id INT REFERENCES users(id), skill_id INT REFERENCES skills(id), default_level SMALLINT,
  level SMALLINT NOT NULL CHECK (level BETWEEN 1 AND 5), source VARCHAR(10) NOT NULL, PRIMARY KEY (user_id, skill_id));
-- D30 技能等級歷史
CREATE TABLE skill_level_history (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), skill_id INT NOT NULL REFERENCES skills(id),
  old_level SMALLINT, new_level SMALLINT NOT NULL, reason VARCHAR(20) NOT NULL, changed_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE user_awards (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), competition VARCHAR(100) NOT NULL,
  level VARCHAR(15) NOT NULL, rank VARCHAR(12) NOT NULL, award_date DATE NOT NULL, FOREIGN KEY (rank, level) REFERENCES award_matrix(rank, level));
CREATE TABLE award_skills (award_id INT REFERENCES user_awards(id) ON DELETE CASCADE, skill_id INT REFERENCES skills(id), PRIMARY KEY (award_id, skill_id));
-- D26 同意紀錄
CREATE TABLE consents (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id), purpose VARCHAR(30) NOT NULL,
  terms_version VARCHAR(10) NOT NULL, agreed_at TIMESTAMPTZ NOT NULL DEFAULT now());

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
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at TIMESTAMPTZ,
  CHECK (type <> 'RESEARCH' OR attribution IS NOT NULL));
CREATE TABLE case_roles (id SERIAL PRIMARY KEY, case_id INT NOT NULL REFERENCES cases(id), role_name VARCHAR(40) NOT NULL,
  headcount SMALLINT NOT NULL CHECK (headcount >= 1), filled_count SMALLINT NOT NULL DEFAULT 0,
  hours_per_week SMALLINT NOT NULL DEFAULT 4, CHECK (filled_count <= headcount));
CREATE TABLE case_role_skills (case_role_id INT REFERENCES case_roles(id), skill_id INT REFERENCES skills(id),
  min_level SMALLINT NOT NULL CHECK (min_level BETWEEN 1 AND 5), is_required BOOLEAN NOT NULL DEFAULT TRUE,
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
  ('purge_months', 6, '畢業後刪除（月）');
