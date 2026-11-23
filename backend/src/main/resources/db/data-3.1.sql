-- 3.1 的示範資料（只在 Demo 模式載入，於遷移之後執行）
-- 內容：把 2.0 遺留的非比賽招募結束掉；建立 8 支對應到競賽清單的比賽隊伍；補上隊伍群組、幾則群組訊息、一筆等待回覆的邀請。
-- 人名、隊名、介紹都是虛構的；比賽取自 ref-competitions.sql，只對報名尚未截止的比賽建立隊伍。
-- AI 助理的端到端測試（tools/napai_e2e.py）用 student002 與他的第一位推薦隊友在 AI CUP 開新隊，這兩個人不要放進 AI CUP 的示範隊伍。

-- 2.0 的招募中案件沒有對應到競賽清單（專題、短期支援、研究協作，或未連結比賽的競賽）。3.1 只做比賽，示範資料把它們結束掉。
UPDATE engagements e SET status = 'DECLINED', decided_at = now()
FROM case_roles r JOIN cases c ON c.id = r.case_id
WHERE e.case_role_id = r.id AND e.status = 'PENDING' AND c.status = 'OPEN' AND c.competition_id IS NULL;
DELETE FROM conversations v USING cases c WHERE c.id = v.case_id AND c.status = 'OPEN' AND c.competition_id IS NULL;
UPDATE case_members m SET active = FALSE FROM cases c WHERE c.id = m.case_id AND c.status = 'OPEN' AND c.competition_id IS NULL;
UPDATE cases SET status = 'CANCELLED' WHERE status = 'OPEN' AND competition_id IS NULL;

-- 建立一支示範隊伍：p_skills 每一項是「技能名稱:最低階級:是否必要」；p_members 是已經加入的成員 Email
CREATE FUNCTION demo_team(p_owner TEXT, p_comp TEXT, p_title TEXT, p_intro TEXT, p_need INT, p_days_ago INT, p_skills TEXT[], p_members TEXT[])
RETURNS VOID AS $$
DECLARE
  v_comp competitions%ROWTYPE; v_owner INT; v_case INT; v_role INT; v_uid INT; v_item TEXT; v_parts TEXT[];
  v_joined INT := coalesce(array_length(p_members, 1), 0); v_hours INT; v_days INT;
BEGIN
  SELECT * INTO v_comp FROM competitions WHERE short_name = p_comp OR name = p_comp LIMIT 1;
  IF NOT FOUND OR NOT v_comp.approved OR v_comp.apply_deadline IS NULL OR v_comp.apply_deadline < current_date THEN RETURN; END IF;
  SELECT id INTO v_owner FROM users WHERE email = p_owner;
  IF NOT FOUND THEN RETURN; END IF;
  SELECT value INTO v_hours FROM system_params WHERE key = 'default_role_hours';
  SELECT value INTO v_days FROM system_params WHERE key = 'team_days_without_event_date';
  INSERT INTO cases (owner_id, title, type, description, team_size, apply_deadline, start_date, end_date, status, created_at, competition_id)
  VALUES (v_owner, p_title, 'COMPETITION', p_intro, 1 + v_joined + p_need,
          (v_comp.apply_deadline + time '23:59') AT TIME ZONE 'Asia/Taipei', current_date - p_days_ago,
          greatest(coalesce(v_comp.event_date, v_comp.apply_deadline + coalesce(v_days, 120)), v_comp.apply_deadline), 'OPEN', now() - make_interval(days => p_days_ago), v_comp.id)
  RETURNING id INTO v_case;
  INSERT INTO case_members (case_id, user_id, is_owner, joined_at, competition_id, active)
  VALUES (v_case, v_owner, TRUE, now() - make_interval(days => p_days_ago), v_comp.id, TRUE);
  INSERT INTO case_roles (case_id, role_name, headcount, filled_count, hours_per_week)
  VALUES (v_case, '隊友', v_joined + p_need, v_joined, coalesce(v_hours, 4)) RETURNING id INTO v_role;
  FOREACH v_item IN ARRAY p_skills LOOP
    v_parts := string_to_array(v_item, ':');
    INSERT INTO case_role_skills (case_role_id, skill_id, min_level, is_required)
    SELECT v_role, s.id, v_parts[2]::INT, v_parts[3] = 'Y' FROM skills s WHERE s.name = v_parts[1];
  END LOOP;
  IF p_members IS NOT NULL THEN
    FOREACH v_item IN ARRAY p_members LOOP
      SELECT id INTO v_uid FROM users WHERE email = v_item;
      IF FOUND THEN
        INSERT INTO case_members (case_id, user_id, case_role_id, joined_at, competition_id, active)
        VALUES (v_case, v_uid, v_role, now() - make_interval(days => greatest(p_days_ago - 1, 0)), v_comp.id, TRUE);
      END IF;
    END LOOP;
  END IF;
END $$ LANGUAGE plpgsql;

SELECT demo_team('student012@example.edu', 'AI CUP 2026 秋季賽（太陽能板瑕疵檢測）', '太陽能小隊',
  '想把瑕疵檢測做到能上線，缺會訓練模型的人。每週固定討論兩次。', 2, 5,
  ARRAY['深度學習:2:Y', '資料分析:1:N'], ARRAY['student019@example.edu']);
SELECT demo_team('student039@example.edu', '為桃園做研究', '桃園觀察隊',
  '做桃園青年返鄉的研究，缺會跑統計、整理問卷的夥伴。', 2, 4,
  ARRAY['統計:1:Y', '問卷設計:1:N'], NULL);
SELECT demo_team('student003@example.edu', 'AIS3 EOF CTF', 'Root 練習生',
  '第一次打 CTF，想找一起練題目的人，新手也歡迎。', 3, 3,
  ARRAY['程式設計基礎:2:Y', '資訊安全:1:N'], NULL);
SELECT demo_team('student005@example.edu', '技嘉奇想設計大賽', '奇想工作室',
  '已經有產品概念和草模，缺會寫企劃、算成本的隊友。', 2, 6,
  ARRAY['商業企劃:2:Y', '行銷企劃:1:N'], ARRAY['student029@example.edu']);
SELECT demo_team('student037@example.edu', '國道智慧創意競賽', '國道數據組',
  '手上有國道流量資料，缺能把分析結果畫清楚的人。', 2, 2,
  ARRAY['資料視覺化:2:Y', '機器學習:1:N'], NULL);
SELECT demo_team('student009@example.edu', 'E化系統創意應用競賽', 'E 化小組',
  '流程和資料表都想好了，缺介面設計。', 3, 1,
  ARRAY['UI/UX 設計:2:Y', '簡報設計:1:N'], NULL);
SELECT demo_team('student024@example.edu', 'Coding101 大學軟體創作競賽', 'Prompt 工坊',
  '想做一個幫同學整理筆記的小工具，已經有後端。', 2, 7,
  ARRAY['生成式 AI 應用:2:Y', 'UI/UX 設計:1:N'], ARRAY['student007@example.edu']);

SELECT demo_team('student008@example.edu', '微軟 Imagine Cup', 'Imagine 提案組',
  '技術原型做好了，缺能把商業模式講清楚的人。', 2, 2,
  ARRAY['商業企劃:2:Y', '簡報設計:2:N'], NULL);

DROP FUNCTION demo_team(TEXT, TEXT, TEXT, TEXT, INT, INT, TEXT[], TEXT[]);

-- 示範隊伍的隊伍群組（和遷移腳本裡的補建相同）
DO $$
DECLARE r RECORD; v_conv INT; v_msg BIGINT;
BEGIN
  FOR r IN SELECT c.id, c.created_at FROM cases c WHERE c.status IN ('OPEN','FORMED','IN_PROGRESS')
             AND NOT EXISTS (SELECT 1 FROM conversations v WHERE v.case_id = c.id AND v.kind = 'TEAM') LOOP
    INSERT INTO conversations (kind, case_id, created_at) VALUES ('TEAM', r.id, r.created_at) RETURNING id INTO v_conv;
    INSERT INTO conversation_members (conversation_id, user_id, joined_at)
      SELECT v_conv, m.user_id, m.joined_at FROM case_members m WHERE m.case_id = r.id;
    INSERT INTO messages (conversation_id, kind, body, created_at) VALUES (v_conv, 'SYSTEM', '隊伍群組已建立', r.created_at) RETURNING id INTO v_msg;
    UPDATE conversations SET last_message_id = v_msg, last_message_at = r.created_at WHERE id = v_conv;
  END LOOP;
END $$;

-- 隊伍群組裡的幾則示範訊息（依時間先後呼叫；說話的人自己算已讀，隊友看到未讀）
CREATE FUNCTION demo_say(p_team TEXT, p_email TEXT, p_body TEXT, p_minutes_ago INT) RETURNS VOID AS $$
DECLARE v_conv INT; v_uid INT; v_msg BIGINT; v_at TIMESTAMPTZ := now() - make_interval(mins => p_minutes_ago);
BEGIN
  SELECT v.id INTO v_conv FROM conversations v JOIN cases c ON c.id = v.case_id WHERE c.title = p_team AND v.kind = 'TEAM' AND c.status = 'OPEN';
  SELECT id INTO v_uid FROM users WHERE email = p_email;
  IF v_conv IS NULL OR v_uid IS NULL THEN RETURN; END IF;
  INSERT INTO messages (conversation_id, sender_id, kind, body, created_at) VALUES (v_conv, v_uid, 'TEXT', p_body, v_at) RETURNING id INTO v_msg;
  UPDATE conversations SET last_message_id = v_msg, last_message_at = v_at WHERE id = v_conv;
  UPDATE conversation_members SET last_read_message_id = v_msg WHERE conversation_id = v_conv AND user_id = v_uid;
END $$ LANGUAGE plpgsql;

SELECT demo_say('太陽能小隊', 'student012@example.edu', '資料集我先整理好放雲端了，瑕疵類別有六種。', 2900);
SELECT demo_say('太陽能小隊', 'student019@example.edu', '收到。我這週先跑一版基準模型，週四給大家看結果。', 2860);
SELECT demo_say('太陽能小隊', 'student012@example.edu', '好，還缺一個人幫忙做資料前處理，我繼續找。', 2850);
SELECT demo_say('奇想工作室', 'student005@example.edu', '草模照片傳上去了，大家看一下握把的比例。', 4300);
SELECT demo_say('奇想工作室', 'student029@example.edu', '握把可以再短一點。另外成本那一頁我不太會算。', 4250);
SELECT demo_say('奇想工作室', 'student005@example.edu', '所以才要找會寫企劃的隊友，我已經開缺了。', 4240);
SELECT demo_say('Prompt 工坊', 'student024@example.edu', '後端的 API 文件我放在共用資料夾。', 1500);
SELECT demo_say('Prompt 工坊', 'student007@example.edu', '看到了，我先把登入頁接起來。', 1440);
DROP FUNCTION demo_say(TEXT, TEXT, TEXT, INT);

-- 一筆等待回覆的邀請：隊長邀請示範帳號加入，洽談對話裡已經有邀請時附的那句話
CREATE FUNCTION demo_invite(p_team TEXT, p_invitee TEXT, p_note TEXT, p_hours_ago INT) RETURNS VOID AS $$
DECLARE v_case INT; v_owner INT; v_role INT; v_uid INT; v_eng INT; v_conv INT; v_msg BIGINT;
        v_owner_name TEXT; v_name TEXT; v_at TIMESTAMPTZ := now() - make_interval(hours => p_hours_ago);
BEGIN
  SELECT c.id, c.owner_id INTO v_case, v_owner FROM cases c WHERE c.title = p_team AND c.status = 'OPEN';
  SELECT id, name INTO v_uid, v_name FROM users WHERE email = p_invitee;
  IF v_case IS NULL OR v_uid IS NULL THEN RETURN; END IF;
  SELECT id INTO v_role FROM case_roles WHERE case_id = v_case ORDER BY id LIMIT 1;
  SELECT name INTO v_owner_name FROM users WHERE id = v_owner;
  INSERT INTO engagements (case_role_id, user_id, direction, status, message, due_at, created_at)
  VALUES (v_role, v_uid, 'INVITE', 'PENDING', p_note, v_at + interval '72 hours', v_at) RETURNING id INTO v_eng;
  INSERT INTO conversations (kind, case_id, engagement_id, created_at) VALUES ('TALK', v_case, v_eng, v_at) RETURNING id INTO v_conv;
  INSERT INTO conversation_members (conversation_id, user_id, joined_at) VALUES (v_conv, v_uid, v_at), (v_conv, v_owner, v_at);
  INSERT INTO messages (conversation_id, kind, body, created_at)
  VALUES (v_conv, 'SYSTEM', v_owner_name || ' 邀請 ' || v_name || ' 加入「' || p_team || '」。可以先在這裡聊聊，再決定要不要接受。', v_at);
  INSERT INTO messages (conversation_id, sender_id, kind, body, created_at) VALUES (v_conv, v_owner, 'TEXT', p_note, v_at) RETURNING id INTO v_msg;
  UPDATE conversations SET last_message_id = v_msg, last_message_at = v_at WHERE id = v_conv;
  UPDATE conversation_members SET last_read_message_id = v_msg WHERE conversation_id = v_conv AND user_id = v_owner;
  INSERT INTO notifications (user_id, type, title, body, link, created_at)
  VALUES (v_uid, 'INVITE', '收到組隊邀請', '「' || p_team || '」邀請你加入。可以先聊聊，再決定要不要接受', '/messages?e=' || v_eng, v_at);
END $$ LANGUAGE plpgsql;

SELECT demo_invite('Imagine 提案組', 'student001@example.edu', '看到你會商業企劃和簡報。我們的原型做好了，想請你幫忙把商業模式講清楚，有興趣聊聊嗎？', 3);
DROP FUNCTION demo_invite(TEXT, TEXT, TEXT, INT);
