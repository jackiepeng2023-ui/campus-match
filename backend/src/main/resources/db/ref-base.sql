-- 正式模式參考資料：技能分類表、學制換算、得獎矩陣（Demo 模式由 data.sql 載入同等資料）
BEGIN;
INSERT INTO skills (name, category) VALUES
  ('Java', '後端'), ('Spring Boot', '後端'), ('Python', '後端'), ('SQL', '後端'), ('Node.js', '後端'),
  ('程式設計基礎', '後端'), ('資料結構與演算法', '後端'), ('作業系統與系統程式', '後端'), ('雲端與網路', '後端'), ('資訊安全', '後端'),
  ('HTML/CSS', '前端'), ('JavaScript', '前端'), ('Vue', '前端'), ('React', '前端'), ('SwiftUI', '前端'), ('網頁開發', '前端'), ('行動應用開發', '前端'),
  ('資料分析', '資料分析'), ('統計', '資料分析'), ('資料視覺化', '資料分析'), ('機器學習', '資料分析'), ('深度學習', '資料分析'), ('數學與數值方法', '資料分析'),
  ('UI/UX 設計', '設計'), ('Figma', '設計'), ('平面設計', '設計'), ('建築與空間設計', '設計'), ('工業與產品設計', '設計'), ('多媒體與影像', '設計'),
  ('簡報設計', '簡報'), ('商業企劃', '簡報'), ('行銷企劃', '簡報'), ('財務分析', '簡報'),
  ('會計與財務', '商管'), ('經濟分析', '商管'), ('管理與組織', '商管'), ('法律與法規', '商管'), ('國際商務', '商管'), ('專案管理', '商管'),
  ('電子電路', '工程'), ('嵌入式與物聯網', '工程'), ('機械設計與製造', '工程'), ('材料與化工', '工程'), ('土木與營建', '工程'), ('環境與水利', '工程'), ('航太與系統', '工程'), ('能源', '工程'),
  ('英文寫作', '語言'), ('英文溝通', '語言'), ('日語', '語言'), ('寫作與文案', '語言'),
  ('問卷設計', '其他'), ('研究方法', '其他'), ('專題與實作', '其他')
ON CONFLICT (name) DO NOTHING;

INSERT INTO grade_conversion VALUES
  ('BACHELOR', 90, 5), ('BACHELOR', 80, 4), ('BACHELOR', 70, 3), ('BACHELOR', 60, 2), ('BACHELOR', 0, 1),
  ('GRADUATE', 90, 5), ('GRADUATE', 85, 4), ('GRADUATE', 80, 3), ('GRADUATE', 70, 2), ('GRADUATE', 0, 1)
ON CONFLICT DO NOTHING;

INSERT INTO award_matrix VALUES
  ('FIRST', 'CAMPUS', 0.5), ('FIRST', 'NATIONAL', 0.8), ('FIRST', 'INTERNATIONAL', 1.0),
  ('TOP3', 'CAMPUS', 0.4), ('TOP3', 'NATIONAL', 0.65), ('TOP3', 'INTERNATIONAL', 0.8),
  ('HONORABLE', 'CAMPUS', 0.25), ('HONORABLE', 'NATIONAL', 0.4), ('HONORABLE', 'INTERNATIONAL', 0.5),
  ('FINALIST', 'CAMPUS', 0.15), ('FINALIST', 'NATIONAL', 0.25), ('FINALIST', 'INTERNATIONAL', 0.3)
ON CONFLICT DO NOTHING;
COMMIT;
