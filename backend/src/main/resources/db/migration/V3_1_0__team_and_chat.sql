-- V3.1.0：只做比賽的主線、即時通訊、報名追蹤（《軟體工程架構 3.1》第 7 節）

-- ===== 隊伍：報名追蹤、名單鎖定、允許一人成隊（D68、D69） =====
ALTER TABLE cases ADD COLUMN registered_at TIMESTAMPTZ;                 -- 隊長標記已報名的時間
ALTER TABLE cases ADD COLUMN registered_by INT REFERENCES users(id);
ALTER TABLE cases ADD COLUMN roster_locked BOOLEAN NOT NULL DEFAULT FALSE;   -- 標記已報名後鎖定名單
ALTER TABLE cases ADD COLUMN reminded_days SMALLINT;                    -- 已送出的報名提醒門檻（7、3、1），避免重複提醒
ALTER TABLE cases DROP CONSTRAINT cases_team_size_check;
ALTER TABLE cases ADD CONSTRAINT cases_team_size_check CHECK (team_size >= 1);

-- ===== 同一場比賽一人一隊（D69）：由部分唯一索引保證，兩個請求同時進來也不會違反 =====
-- active：這筆成員資格是否計入「同一場比賽一人一隊」。隊伍取消、過期、結束時設為否；成員退出或被請離時直接刪除該列。
ALTER TABLE case_members ADD COLUMN competition_id INT REFERENCES competitions(id);
ALTER TABLE case_members ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
UPDATE case_members m SET competition_id = c.competition_id,
       active = c.status IN ('DRAFT','OPEN','FORMED','IN_PROGRESS','CLOSING')
FROM cases c WHERE c.id = m.case_id;
-- 既有資料若已經違反（同一人在同一場比賽有兩支進行中的隊伍），只讓最早加入的那一筆計入
UPDATE case_members m SET active = FALSE
WHERE m.active AND m.competition_id IS NOT NULL AND EXISTS (
  SELECT 1 FROM case_members o
  WHERE o.competition_id = m.competition_id AND o.user_id = m.user_id AND o.active
    AND (o.joined_at, o.case_id) < (m.joined_at, m.case_id));
CREATE UNIQUE INDEX uq_member_competition ON case_members (competition_id, user_id) WHERE active AND competition_id IS NOT NULL;

-- ===== 即時通訊（D70）：對話只有兩種，都掛在流程上 =====
CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  kind VARCHAR(4) NOT NULL CHECK (kind IN ('TALK','TEAM')),      -- TALK 洽談（申請人或被邀請人與隊長）；TEAM 隊伍群組
  case_id INT NOT NULL REFERENCES cases(id),
  engagement_id INT UNIQUE REFERENCES engagements(id),           -- 洽談才有；一筆申請或邀請只有一個洽談對話
  read_only BOOLEAN NOT NULL DEFAULT FALSE,                      -- 婉拒、取消、逾時後唯讀；隊伍結束後群組唯讀
  last_message_id BIGINT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  CHECK ((kind = 'TALK') = (engagement_id IS NOT NULL)));
CREATE UNIQUE INDEX uq_conversation_team ON conversations (case_id) WHERE kind = 'TEAM';   -- 一支隊伍只有一個隊伍群組
CREATE INDEX ix_conversations_case ON conversations (case_id);

CREATE TABLE conversation_members (
  conversation_id INT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id INT NOT NULL REFERENCES users(id),
  joined_at TIMESTAMPTZ NOT NULL,
  left_at TIMESTAMPTZ,                                           -- 退出或被請離的時間；之後整個對話都看不到
  since_message_id BIGINT NOT NULL DEFAULT 0,                    -- 加入時對話的最後一則訊息；只看得到編號比它大的（看不到加入前的討論）
  last_read_message_id BIGINT NOT NULL DEFAULT 0,                -- 未讀數由它計算
  PRIMARY KEY (conversation_id, user_id));
CREATE INDEX ix_conversation_members_user ON conversation_members (user_id);

CREATE TABLE messages (
  id BIGSERIAL PRIMARY KEY,                                      -- 同一個對話內遞增；順序與補漏都以它為準
  conversation_id INT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id INT REFERENCES users(id),                            -- 系統訊息為空
  kind VARCHAR(6) NOT NULL CHECK (kind IN ('TEXT','SYSTEM')),
  body VARCHAR(2000) NOT NULL,
  client_id VARCHAR(40),                                         -- 用戶端產生的編號；重送時不會變成兩則
  created_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ);                                       -- 到期清空內容時填入
CREATE INDEX ix_messages_conversation ON messages (conversation_id, id);
CREATE UNIQUE INDEX uq_message_client ON messages (sender_id, client_id) WHERE client_id IS NOT NULL;
CREATE INDEX ix_messages_sender ON messages (sender_id, created_at);                     -- 每分鐘則數上限的檢查

-- 既有的進行中隊伍補上隊伍群組
DO $$
DECLARE r RECORD; v_conv INT; v_msg BIGINT;
BEGIN
  FOR r IN SELECT c.id FROM cases c WHERE c.status IN ('OPEN','FORMED','IN_PROGRESS')
             AND NOT EXISTS (SELECT 1 FROM conversations v WHERE v.case_id = c.id AND v.kind = 'TEAM') LOOP
    INSERT INTO conversations (kind, case_id, created_at) VALUES ('TEAM', r.id, now()) RETURNING id INTO v_conv;
    INSERT INTO conversation_members (conversation_id, user_id, joined_at)
      SELECT v_conv, m.user_id, now() FROM case_members m WHERE m.case_id = r.id;
    INSERT INTO messages (conversation_id, kind, body, created_at) VALUES (v_conv, 'SYSTEM', '隊伍群組已建立', now()) RETURNING id INTO v_msg;
    UPDATE conversations SET last_message_id = v_msg, last_message_at = now() WHERE id = v_conv;
  END LOOP;
END $$;

-- ===== 可調參數 =====
INSERT INTO system_params (key, value, label) VALUES
  ('default_role_hours', 4, '開隊時預設的每週需求時數'),
  ('team_days_without_event_date', 120, '比賽沒有公告日期時，報名截止後幾天視為比賽結束'),
  ('message_rate_per_minute', 30, '每人每分鐘可送出的訊息數'),
  ('message_retention_days', 90, '隊伍結束後訊息內容保留天數')
ON CONFLICT (key) DO NOTHING;
-- 2.0 的參數沿用，說明改成 3.1 的用語；比賽結束隔天就結束隊伍並開始互評（2.0 是結束日後 7 天自動結案）
UPDATE system_params SET label = '每人同時招募中的隊伍上限（0 = 不設限）' WHERE key = 'max_open_cases';
UPDATE system_params SET label = '每人等待回覆的申請上限（0 = 不設限）' WHERE key = 'max_pending_applications';
UPDATE system_params SET value = 1, label = '比賽結束後幾天自動結束隊伍並開始互評' WHERE key = 'auto_close_days';
