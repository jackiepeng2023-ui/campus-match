-- 教師參考資料：由 tools/ref_napai.py 從 tools/data/teachers.json 產生；只含系所網站公開的姓名、職稱、專長、研究方向、指導經歷與來源連結
BEGIN;
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉安之', '春雨講座', d.id, '網路管理、分散式系統、資料庫系統', '', '', 'https://www.iecs.fcu.edu.tw/acliu', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉安之' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張真誠', '何宜武先生學術講座', d.id, '資料庫設計、電子商務安全、電子多媒體影像技術、電腦密碼學、圖像與信號處理、信息取證與安全、深度學習', '張教授對資訊安全、密碼學與多媒體圖像處理等領域有卓越貢獻', '指導學生競賽／獲獎紀錄（官網列7筆）：2012 MATLAB 程式達人競賽佳作獎／鈦思科技（2012）；競賽佳作獎／鈦思科技（2012）；博士論文獎／中華民國民生電子學會（2015）；2013 MATLAB/Simulink 論文徵文／鈦思科技（2013）；博士論文首獎／中華民國（1992）', 'https://www.iecs.fcu.edu.tw/alan3c', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張真誠' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '桑慧敏', '講座教授', d.id, '青光眼預測分析、太陽能與半導體製程品質管制與可靠度、電力節能之最佳設計、機率統計與模擬理論與應用、系統思維', '國科會計畫：應用 AI 於半主動至主動式防振系統之感測回授與電源逆變器驅動控制最佳化（2026）；基於眼底與斷層影像之多模態青光眼鑑別、縱向建模與跨院可複現驗證框架（2026）；提升航空零件製程穩定性之空調變頻AI控制策略（2025）', '', 'https://www.iecs.fcu.edu.tw/wheyming_song', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '桑慧敏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '竇其仁', '特聘教授', d.id, '行動計算、車載網路、智慧聯網、雲端計算、學習科技', '國科會計畫：電動汽車充電站場域充電服務模式預估系統（2024）；設計與實作一個基於交通號誌燈與車聯網之警示系統（2024）；基於智慧路燈即時路口交通串流影像之行人安全監控系統（2023）', '指導學生競賽／獲獎紀錄（官網列1筆）：電腦系統組優等獎／91年度全國校園軟體創作競賽（2002）', 'https://www.iecs.fcu.edu.tw/crdow', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '竇其仁' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李榮三', '特聘教授', d.id, '網路安全、區塊鏈技術與應用、後量子密碼、零信任架構、大語言模型安全', '國科會計畫：基於多層式AI學習能力建構自適應進階持續性威脅防禦系統（2026）；遵循ISO 27037/NIST SP 800-201建構可信任證據管理之雲端數位鑑識系統（2026）；基於行為分析與後量子密碼區塊鏈之動態零信任驗證框架（2025）', '指導學生競賽／獲獎紀錄（官網列6筆）：2024 GiCS第4屆尋找資安女婕思競賽優勝／國科會與教育部（2024）；2024 GiCS第4屆尋找資安女婕思競賽第一名／國科會與教育部（2024）；2023 GiCS第3屆尋找資安女婕思競賽佳作／國科會與教育部（2023）；2023 GiCS第3屆尋找資安女婕思競賽優勝／國科會與教育部（2023）；2023 GiCS第3屆尋找資安女婕思競賽第一名／國科會與教育部（2023）', 'https://www.iecs.fcu.edu.tw/leejs', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李榮三' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王益文', '副教授', d.id, '嵌入式系統設計、VLSI系統設計、類神經網路', '國科會計畫：基於執行時間回授控制ESP32-S3記憶體頻寬動態調節機制（2026）；基於深度強化學習的雙足機器人步態控制：利用NVIDIA Omniverse比較DDPG與SAC演算法（2025）；可用於視障輔助之對話系統（2019）', '', 'https://www.iecs.fcu.edu.tw/ywang', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王益文' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李金鳳', '教授', d.id, '資料庫資訊系統設計、電子多媒體影像技術、電腦密碼學、資訊隱藏與浮水印技術、資料探勘與機器學習', '近5年國科會計畫聚焦於數位影像的資訊安全，提升可逆式資訊隱寫技術之效能與應用，進一步結合 Variational Autoencoders (VAE) 與Generative Adversarial Networks (GAN) 設計影像認證架構，具備篡改偵測、定位與復原功能', '', 'https://www.iecs.fcu.edu.tw/%E6%9D%8E%E9%87%91%E9%B3%B3', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李金鳳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李俊宏', '副教授', d.id, '人工智慧、智慧代理人、軟體工程、模糊時間序列', '主要研究領域為人工智慧與軟體工程，特別是人工智慧技術於軟體工程與財金領域之應用。', '', 'https://www.iecs.fcu.edu.tw/chiunghon', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李俊宏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李維斌', '教授', d.id, '網路安全、密碼學、數位浮水印、資訊安全管理', '', '指導學生競賽／獲獎紀錄（官網列4筆）：全國大專院校資安技能金盾獎／資訊工業策進會（2010）；「全國大專院校資安技能金盾獎」／資訊工業策進會（2009）；「第三屆全國大專院校資安技能金盾獎」--潛力無窮獎／資訊工業策進會（2008）；TANET2010佳作論文獎／TANET 2010臺灣網際網路研討會（2010）', 'https://www.iecs.fcu.edu.tw/wblee', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李維斌' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周兆龍', '副教授', d.id, '資訊安全、藏密分析、影像處理、生物識別、零信任', '國科會計畫：智慧型個人化社交工程資安訓練平台：SENSE互動式談判與情境模擬系統（2026）；針對中文深偽影音之多模態特徵融合檢測平台開發（2026）；基於集成學習與融合生物行為特徵之零信任架構持續性認證技術（2024）', '', 'https://www.iecs.fcu.edu.tw/%E5%91%A8%E5%85%86%E9%BE%8D', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周兆龍' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林哲維', '助理教授', d.id, '人工智慧、自然語言處理、中文故事分析與生成、電腦視覺與人臉識別', '主要的研究領域包含人工智能、自然語言處理、中文故事生成以及電腦視覺等識別方法。在人工智慧與自然語言的研究主要專注在中文內文的解析與強化模型對句子的理解能力，並透過深度學習的方式來進行長短句子的生成與對話等應用。', '指導學生競賽／獲獎紀錄（官網列2筆）：2023 全國私立大專校院誠是競賽／銘傳大學（2023）；2022 永續智慧創新黑客松競賽／靜宜大學（2022）', 'https://www.iecs.fcu.edu.tw/jhewlin', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林哲維' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林志敏', '教授', d.id, '軟體代理人技術與應用、嵌入式系統、作業系統、軟體整合與重用、計算機算術、機器人技術與應用', '國科會計畫：多機器人系統輔助英語課堂教學之實作與其學習成效（2023）；以 Rust 程式語言改寫 Linux Kernel Module 以增強其記憶體管理安全性 - 以 ksmbd 模組為例（2023）；機器人輔助英語朗讀錯誤診斷與治療系統與成效評估之研究（2022）', '', 'https://www.iecs.fcu.edu.tw/jimmy', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林志敏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林峰正', '副教授', d.id, '人工智慧、資料分析、演算法、雲端運算應用、影像處理、深度學習', '研究主題包含雲端運算、深度學習、影像處理、商業智慧、地理資訊系統。研究重點及興趣為處理城市數位資料為主，在實作面上，大量使用 Python、R、Matlab 執行數據運算分析，分別為影像以及文字處理。', '指導學生競賽／獲獎紀錄（官網列57筆）：AI Manufacturing 2026 全國AI智慧製造競賽／國立雲林科技大學（2026）；萬潤2026創新創意競賽-大專組 (佳作)／公益信託萬潤慈善基金、萬潤科技股份有限公司（2026）；2026 萬潤 創新創意競賽碩博士論文組 (佳作)／公益信託萬潤慈善基金、萬潤科技股份有限公司（2026）；中華電信「智慧創新應用大賽」入圍決賽／中華電信（2026）；第一屆 富品盃AI創新應用競賽-銅獎 (優等獎)／富品集團 | 富品建設（2026）', 'https://www.iecs.fcu.edu.tw/fclin', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林峰正' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林明言', '教授', d.id, '資料探勘與資料庫、巨量資料分析、可解釋之人工智慧、推薦系統、智慧醫療', '主要的研究興趣是資料庫、資料探勘與巨量資料分析。', '個人簡介：曾四度獲得中華民國資訊學會最佳碩博士論文獎佳作指導老師獎。 指導學生競賽／獲獎紀錄（官網列16筆）：大專學生研究計畫創作獎／科技部（2021）；第二屆中區資訊專題成果競賽暨觀摩會資訊應用組 第二名／中華電信基金會（2012）；2012逢甲大學資訊電機學院畢業專題製作競賽暨觀摩展 佳作／逢甲大學資訊學院（2012）；2012跨領域創意網路通訊應用與服務競賽特優獎／教育部/網通應用服務平台技術教學推動聯盟（2012）；2011逢甲大學行動終端應用程式設計競賽／逢甲大學（2011）', 'https://www.iecs.fcu.edu.tw/%E6%9E%97%E6%98%8E%E8%A8%80', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林明言' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林佩君', '副教授', d.id, '模糊統計、統計建模、感性工學、大數據分析、人工智慧開發與應用', '目前林教授專攻領域包括模糊計算，人工智能運算，機器人計算，統計建模，雲端計算和大數據分析等相關領域。', '', 'https://www.iecs.fcu.edu.tw/peiclin', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林佩君' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林佩蓉', '副教授', d.id, '延展實境科技、AI影像辨識、腦機介面技術、醫療資訊、無線網狀網路', '研究專長為腦機介面技術、延展實境人機互動技術、無線網狀網路、醫療資訊應用等。目前正在進行的研究包含混合實境技術與醫學物理治療之跨領域實務應用研究、虛擬實境與腦波整合技術、以及無人機影像辨識應用等。', '個人簡介：期間培育的團隊參加國內外各類型競賽獲得逾百件得獎記錄 指導學生競賽／獲獎紀錄（官網列32筆）：第一名 / 2026第31屆大專校院資訊應用服務創新競賽—職安視覺化防災及素養提升組／教育部、中華民國資訊管理學會、勞動部(職業安全衛生署)（2026）；銅獎 / 2026 Taiwan Online Programming Contest 台灣程式競賽(國際ICPC 台灣區域賽)／Taiwanese Association for Collegiate Programming Contest, ICPC Foundation（2026）；銅獎 / PUPC 2026-第16屆全國私立大專校院程式設計競賽／逢甲大學資訊處、逢甲大學資訊工程學系（2026）', 'https://www.iecs.fcu.edu.tw/%E6%9E%97%E4%BD%A9%E8%93%89', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林佩蓉' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪振偉', '副教授', d.id, '軟體工程(軟體系統開發、設計樣式、軟體架構)、行動應用設計、資訊教育、電腦輔助語言學習、物聯網應用開發', '研究專長為軟體工程、系統開發以及資訊教育等，未來希望朝向應用物聯網於跨領域以及資料科學等相關研究', '', 'https://www.iecs.fcu.edu.tw/zwhong', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪振偉' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪維志', '副教授', d.id, '無線網路、行動網路、資訊安全、密碼分析、硬體安全', '國科會計畫：以深度學習技術改進旁通道抵禦能力檢測與訊號軌跡預處理（2021）；人工智慧時代的硬體安全：威脅與防護（2021）；關鍵資訊基礎設施的資安與隱私防護機制的設計與實作（2020）', '', 'https://www.iecs.fcu.edu.tw/wchong', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪維志' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張志宏', '副教授', d.id, '軟體工程、雲端服務、深度學習、智慧醫療、巨量資料', '主要研究成果方向為深度學習、軟體工程、雲端服務、健康照護系統等相關之研究。合作人工智慧資料分析、大語言模型應用、多元能源管理等實際應用，如常新冠分析、骨科罕見疾病診斷、癲癇偵測、衛教機器人等。', '', 'https://www.iecs.fcu.edu.tw/%E5%BC%B5%E5%BF%97%E5%AE%8F', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張志宏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '郭士煒', '助理教授', d.id, '影像辨識與物件偵測、生成式人工智慧、自然語言處理、網路安全、資訊安全、智慧醫療應用', '研究專長包括自然語言處理 (NLP)、生成式人工智慧 (Generative AI)、持續學習 (Continual Learning)、網路安全 (Cybersecurity) 與社群媒體分析 (Social Media Analysis)。未來研究方向著重於智慧資安與人工智慧的發展，特別關注大型語言模型 (LLM) 在安全領域的應用與挑戰。', '', 'https://www.iecs.fcu.edu.tw/%E9%83%AD%E5%A3%AB%E7%85%92', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '郭士煒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '郭崇韋', '助理教授', d.id, '積體電路電磁相容、微控制器應用、硬體安全、惡意流量分析', '主責積體電路電磁干擾雜訊、無線電天線效能以及協助車載無線電EMC試驗技術等研究分析，此外，也一同與合作廠商設計開發能在物聯網設備應用的具抵抗旁通道攻擊的方案。', '', 'https://www.iecs.fcu.edu.tw/cwkuo', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '郭崇韋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張哲誠', '教授兼系主任', d.id, '自駕車、無人機、異常檢測、聯邦式學習、平行分散式計算、機器學習、深度學習', '目前正在進行的研究包含人工智慧演算法整合電腦視覺的智慧車輛系統開發、嵌入式系統應用開發與平行及分散式系統演算法設計。', '指導學生競賽／獲獎紀錄（官網列9筆）：2026 全國私立大專校院程式設計競賽 銅獎／逢甲大學（2026）；2025 ITSA全國大專校院程式設計極客挑戰賽 佳作／成功大學（2025）；2025 全國私立大專校院程式設計競賽 銀獎／靜宜大學（2025）；2024 工業機器人競賽-無人車競速賽（大專組） 佳作／台灣工業機器人協會（2024）；2022 永續智慧創新黑客松競賽 佳作／靜宜大學（2022）', 'https://www.iecs.fcu.edu.tw/checchang', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張哲誠' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳青文', '教授', d.id, '高效能低功率多核心系統、嵌入式系統與周邊驅動、無線隨意行動與感測網路', '國科會計畫：實現 C23 相容且可移植優化的多編譯器組合設計：以 slimcc 與 shecc 結合為例（2025）；結合手機姿勢識别與社群競爭以促進身體活動習慣養成（2024）；演算法家家酒：具LEGO 遊戲關卡影像辨識與體現操作之遊戲式演算法學習系統開發與評估（2023）', '', 'https://www.iecs.fcu.edu.tw/chingwen', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳青文' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳德生', '副教授', d.id, 'VLSI 電腦輔助設計、嵌入式系統、智慧聯網', '國科會計畫：後量子密碼學CRYSTALS-Kyber之模算術電路設計與最佳化研究（2025）；Boid演算法在音訊輸入引導下於活動場地人流管理中的模擬與分析（2024）；應用於多圖案微影技術之研究（2023）', '', 'https://www.iecs.fcu.edu.tw/dschen', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳德生' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳錫民', '教授', d.id, '軟體工程、DevOps技術、服務導向運算、分散式運算', '國科會計畫：以生成式AI為基底的程式碼審查輔助系統之研發（2026）；基於LLM協作代理人的BDD 需求規格到 OpenAPI 文件自動生成系統之研發（2026）；發展AI輔助工具以提升資訊科系學生UI設計能力之研究（2026）', '指導學生競賽／獲獎紀錄（官網列24筆）：永續智慧創新黑客松競賽-健康管理大數據平台在藥局的應用(大樹藥局)-第一名／中部11校（2025）；第十屆海峽兩岸青少年創客大賽-三等獎／逢甲大學/同濟大學/福州大學（2025）；2022永續智慧創新黑客松競賽-智慧物聯網應用與管理組／靜宜大學（2022）；2020 ITSA極客挑戰賽-佳作／教育部（2020）；智慧終端與人機互動軟體創作專題競賽-佳作／教育部（2018）', 'https://www.iecs.fcu.edu.tw/hsiminc', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳錫民' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳烈武', '教授', d.id, '無線通訊與行動計算、車聯網、物聯網與人聯網、機器學習與人工智慧', '國科會計畫：基於車聯網增進行車安全與效率之協同式車道等級智慧運輸系統（2026）；基於風險預估與語意通訊最佳化行車效率之自適應路口通行系統（2026）；基於物聯網具備沉浸式街景自動生成之虛實整合互動路跑系統（2025）', '指導學生競賽／獲獎紀錄（官網列97筆）：佳作論文獎(Merit Paper Award)／第18屆台灣管理學會論文大賞2025：AI應用論文競賽（2025）；資訊組「特優獎」／中國工程師學會學生工程論文競賽2024（2024）；大專學生研究創作獎／國科會（2023）；資訊組「特優獎」／中國工程師學會學生工程論文競賽2023（2023）；友達場域創新應用組「第一名」／第27屆全國大專校院資訊應用服務創新競賽2022（2022）', 'https://www.iecs.fcu.edu.tw/lwuchen', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳烈武' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '許芳榮', '教授', d.id, '雲端運算、生物資訊、人工智慧、醫學影像', '國科會計畫：應用深度學習於護理術科評量之智慧系統建構與驗證—以Video-to-SOP Matching為核心架構（2026）；結合 3D 深度學習與大型語言模型於肺部電腦斷層影像之結節偵測與自動化診斷報告生成（2026）；透過整合 3D 空間追蹤和深度學習模型揭示斑馬魚行為（2024）', '', 'https://www.iecs.fcu.edu.tw/frhsu', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '許芳榮' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃秀芬', '教授', d.id, '計算機演算法、圖學理論、互連結網路、無線隨意及感測網路', '', '', 'https://www.iecs.fcu.edu.tw/sfhwang', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃秀芬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '游景盛', '副教授', d.id, '生物資訊、結構生物資訊、計算系統生物', '國科會計畫：以單光子么正運算與鏈式結構編碼建構免量子延遲線圈的輕量化量子金鑰分配協定（2026）；透過藥物-標靶的物化特徵與空間的契合關係以機器學習方法改進標靶辨識（2025）', '', 'https://www.iecs.fcu.edu.tw/%E6%B8%B8%E6%99%AF%E7%9B%9B', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '游景盛' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '葉春秀', '副教授', d.id, '影像處理、智能製造、專案管理、物件導向、影像辨識', '主要的研究方向為專案管理、物件導向、影像辨識、智能製造。', '個人簡介：帶領學生參與校內外專題競賽以及國內APP競賽獲獎多次。', 'https://www.iecs.fcu.edu.tw/chunhyeh', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '葉春秀' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉明機', '副教授', d.id, '創新學習軟體設計、教育資料科學、情感運算、認知神經科學', '國科會計畫：運用 AI 代理人技術自動化生成基於認知負荷理論之多元教學策略的 Podcast 內容（2026）；結合離線 RAG 口袋知識庫的災難情境對話演練以提升防災韌性（2026）；虛擬人物導引之正念遊戲於自助點餐系統的應用：對飲食選擇與食物體驗的影響（2025）', '指導學生競賽／獲獎紀錄（官網列97筆）：銅獎／2026 ICPC 臺灣線上程式競賽(TOPC 2026)（2026）；銅獎／第十六屆全國私立大專校院程式競賽(PUPC 2026)（2026）；金獎／第十六屆全國私立大專校院程式競賽(PUPC 2026)（2026）；2026 逢甲大學共善創新競賽「佳作」／逢甲大學（2026）；佳作／2025 國際大學生程式競賽(ICPC)台中區域賽（2025）', 'https://www.iecs.fcu.edu.tw/%E5%8A%89%E6%98%8E%E6%A9%9F', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉明機' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉宗杰', '教授', d.id, '分散式系統、網路安全、自我穩定系統、大數據分析', '國科會計畫：Log Analysis for Event Detection with AI（2025）；基於Rust與Web技術之集中式Linux主機管理系統研究與實作（2025）', '', 'https://www.iecs.fcu.edu.tw/%E5%8A%89%E5%AE%97%E6%9D%B0', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉宗杰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉怡芬', '副教授', d.id, '機率論、機器學習、語音辨識、自然口語處理與辨識、計算語言學', '目前研究領域包含：運用語音工程技術於醫療的構音異常檢測/評估系統、華語學習者的聲調模型，以及如何運用語音訊號幫助識別兩個語意事件之間的言談關係。', '', 'https://www.iecs.fcu.edu.tw/%E5%8A%89%E6%80%A1%E8%8A%AC', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉怡芬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡國裕', '副教授', d.id, '密碼學、物聯網應用與安全、行動商務與安全', '主要研究領域為區塊鏈應用、物聯網應用與安全、行動裝置應用開發、電子商務應用，目前主要研究方向為電子貨幣、智能合約、物聯網之遠端居家照護應用、Android App保護等', '', 'https://www.iecs.fcu.edu.tw/%E8%94%A1%E5%9C%8B%E8%A3%95', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡國裕' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡明翰', '副教授', d.id, '電腦視覺、電腦圖學、虛擬實境、擴增實境', '主要研究領域為電腦視覺、電腦圖學、虛擬實境與擴增實境。專長為虛擬實境與人體感知之研究，以及擴增實境和電腦視覺的結合。', '', 'https://www.iecs.fcu.edu.tw/%E8%94%A1%E6%98%8E%E7%BF%B0', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡明翰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '薛念林', '教授', d.id, '軟體工程、軟體品質驗證、物件設計', '主要研究領域為軟體工程，特別是軟體設計與軟體測試系統領域。', '', 'https://www.iecs.fcu.edu.tw/nlhsueh', 'https://www.iecs.fcu.edu.tw/teacher/', '2026-11-11'
FROM departments d WHERE d.name = '資訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '薛念林' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉文豐', '特聘教授', d.id, '光纖光學、光纖通訊、光纖光柵、電子學、光纖感測器', '國科會計畫：前瞻型光纖光柵生化感測系統之研發（115學年度）；光纖光柵人體脈波感測器 Human Pulse Sensor Based on a Fiber Bragg Grating（115學年度）；高端設備之二維光纖震動感測器（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T91039&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉文豐' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '田春林', '特聘教授', d.id, '視覺光學設計、薄膜殘留應力、光學檢測、光纖感測器、薄膜特性量測、微光學元件', '國科會計畫：無人機雲台用雷射測距模組性能測試評估系統研製（115學年度）；結合光學薄膜及損耗模態共振技術以研製高靈敏度多樣氣體感測系統（115學年度）；光學鍍膜製程沉積厚度及內應力線上檢測系統開發（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T90136&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '田春林' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪耀正', '特聘教授', d.id, '統計與計算物理、非線性動力學、複雜訊號分析、物理教育', '國科會計畫：結合實體教具與Vibe Coding互動模擬教學模組之開發：改善中學生在轉動運動的迷思概念（115學年度）；Qubits Go：量子計算桌遊的開發與推廣（114學年度）；物理魔術教具的開發與推廣（113學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T01219&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪耀正' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '何子儀', '教授', d.id, '微處理機應用設計、馬達驅動器設計與製作、電力電子電路設計、EMI防制與對策、電力電子系統、微處理機之應用、驅動器控制工程', '國科會計畫：自動導引車充電系統之設計與製作（115學年度）；具循跡、導引與避障功能自動導引車系統之製作與研究（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T81133&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '何子儀' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '梁寶芝', '教授', d.id, '液晶物理、液晶光學、液晶顯示器、光學、光電工程', '國科會計畫：簡易製程二維液晶光柵之研究（114學年度）；電動腳踏車再生煞車系統之製作與研究（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T81180&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '梁寶芝' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃思倫', '教授', d.id, '電力系統、電力品質、軌道供電系統、綠色能源發電系統', '國科會計畫：基於弛豫電壓物理模型之鋰電池非侵入式健康評估與機理導向預測技術研究（115學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T82028&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃思倫' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳坤煌', '教授', d.id, '光電工程、光學測量、全像光學元件', '國科會計畫：相位式影像感測技術之研究與應用（115學年度）；3D場景重建技術之研究與應用（113學年度）；深度感測技術之研究與應用（111學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T93016&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳坤煌' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李企桓', '教授', d.id, 'ZEMAX、G-solver 光柵與ASAP 光學模擬技術、色彩分光顯示系統開發、次波長光柵研究與分析技術、陶瓷複合材料及晶體結構計算', '國科會計畫：智慧動態簽名驗證之「金鑰開箱」視覺化：以遊戲化介面提升資安互動體驗與鑑別效率/"Loot Box" Visualization for Intelligent Dynamic Signature Verification: Enhancing Cybersecurity Interaction and Authenticati（115學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T99046&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李企桓' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝振中', '教授兼系主任', d.id, '電力電子、電機與磁性元件設計、輸配電系統設計、智慧財產權(專利)', '國科會計畫：具寬輸入寬輸出電壓單相單級交流-雙直流源輸出LLC諧振轉換器之研究（115學年度）；具開關容錯診斷與控制半橋對主動式中性點箝位7階直流-交流轉換器之研究（114學年度）；打造友善綠色城市實現公共自行車能量回收與利用系統研製（113學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T08041&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝振中' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '齊立平', '教授', d.id, '微波工程、天線設計、電磁理論', '', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T93164&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '齊立平' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王壘', '副教授', d.id, '計算機結構、嵌入式系統、網路協定、系統安全、人工智慧', '國科會計畫：基於PPG訊號之多重特徵提取以實現複合式多通道卷積神經網路模型的血壓量測（112學年度）；結合模組化AIoT感應器無線網路與深度學習技術之雲端即時工具機維護診斷系統（110學年度）；以PPG訊號開發並實作一個穿戴式血壓監控系統（109學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T79098&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王壘' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳志強', '副教授', d.id, '平面天線設計與分析、平面波導傳輸線電路設計與分析、天線、電路縮裝設計與分析、轉換結構設計與分析、電磁應用、微型化電磁感測器之設計與分析、平面微帶天線、波導被動元件、微波積體電路縮裝、微波信號處理、射頻辨識器RFID應用', '國科會計畫：5G NR n77/n78/n79應用頻段之手機天線設計（111學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T94126&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳志強' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '曹嶸', '副教授', d.id, '天線設計、電磁場與電磁波、電磁相容', '國科會計畫：應用於5G/6G之變線寬電感整合被動元件研究（115學年度）；小型化基地台之寬頻雙極化天線（112學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T01035&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '曹嶸' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃定彝', '副教授', d.id, '電磁理論分析與數值計算、天線與電波傳播、微波與毫米波元件與電路、封裝與系統整合', '國科會計畫：在低損耗陶瓷基板研製IPD高頻共振器（115學年度）；應用於n257頻段之毫米波圓極化天線（112學年度）；模組化智慧型行動裝置中差動訊號的非接觸傳輸介面分析與補償設計（110學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T04253&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃定彝' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪聖均', '副教授', d.id, '場效電晶體生物感測與半導體元件、光電與奈米介面生物感測、智慧生醫感測與物聯網醫療系統', '國科會計畫：以 HER2 模型分子探討電雙層介電調制與界面電荷耦合於延伸閘極場效電晶體之物理機制研究（115學年度）；簡易製程二維液晶光柵之研究（114學年度）；靈敏度可調變的液體濃度量測裝置之研究（111學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T10285&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪聖均' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '徐士賢', '助理教授', d.id, '深度學習於太陽光電功率預測、光儲微電網智慧能源管理與最佳化調度、智慧馬達故障診斷與邊緣人工智慧、智慧電池狀態估測與健康管理、電力系統接地與電氣安全、智慧船舶電力與能源管理系統', '國科會計畫：基於數據融合之深度遷移學習模型於鋰離子電池健康狀態估測之研究（115學年度）；校園分散式光儲微電網之電力調度與能源效益研究（115學年度）；結合數據驅動模型與邊緣運算於鋰離子電池組之SOC與SOH在線估測（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T04331&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '徐士賢' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃俊瑋', '助理教授', d.id, '電力系統運轉實務與數位孿生監控物聯網、智慧能源管理與最佳化應用、電力電子分析與轉換器設計、人工智慧演算法設計與類神經網路控制、淨零科技與低碳化電力分析、永續能源發展與綠色科技應用', '國科會計畫：面向淨零校園之能源代理人：基於多流動態協同調度與聯邦式深度強化學習的韌性能源與碳排運營平台設計（115學年度）；基於AI 視覺覆核與氣壓分揀技術之輕量化智慧配藥及用藥指引平台（115學年度）；數位孿生與綠能驅動車電系統開發（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T10056&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃俊瑋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王志洋', '助理教授', d.id, '開放量子系統之理論與計算、量子電腦晶片設計、電磁波傳導與光電元件之數值模擬、半導體與太陽能電池效能之數值模擬、光子晶體理論與數值計算、表面電漿子理論與相關應用之數值模擬、以COMSO軟體建立多物理計算序', '國科會計畫：以讀取保真度為導向的Purcell濾波量子位元讀取電路分析與自動化設計框架（115學年度）；基於集總振盪器模型之超導量子晶片自動化設計與分析程序（115學年度）；強化學習輔助超導量子電路設計自動化（114學年度）', '', 'https://ee.fcu.edu.tw/teachers-detail/?id=T13186&unit_id=CE11', 'https://ee.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電機工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王志洋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '許士軍', '高人言先生學術講座', d.id, '創新管理、經營策略與行銷、研究方法、組織理論', '', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T02256&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '許士軍' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '佘日新', '講座教授', d.id, '科技管理與行銷、智慧財產權、策略管理、國際企業管理、文化創意產業經營', '國科會計畫：新興科技創新營運模式－台灣智慧製造創新營運中心-總計畫及子計畫二、四、五（108學年度）；智能纖維與紡織品之創新研發（108學年度）；個人創新行為與家族企業傳承之研究（108學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T03177&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '佘日新' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張秀樺', '特聘教授兼系主任', d.id, '行銷策略、行銷研究、數位行銷、企劃實務、行銷倫理、永續消費', '國科會計畫：愈壞我越愛?!探討網紅違規行為之跨文化消費者觀點（115學年度）；K-pop專輯垃圾亂象─探討情感依附對粉絲處置行為的影響（115學年度）；探討消費者自願性碳抵銷支付意願：整合倫理決策模式、保護動機理論與道德背離（114學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T03098&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張秀樺' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '顏上詠', '教授', d.id, '智慧財產權、生物科技法制與產業政策、奈米科技法制與產業政策', '', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T91127&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '顏上詠' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃誠甫', '教授', d.id, '網路分析、系統可靠度、製程能力分析', '國科會計畫：基於時間損壞率之隨機流量物流網路的網路可靠度評估與最佳化研究（115學年度）；整合隨機規劃與深度學習於預算配置下多階狀態電腦網路韌性評估與強化決策之研究（115學年度）；整合異質製程數據與隱性知識之混合智能決策支援系統：碳鋼管產線雙軸轉型架構之發展（114學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T01079&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃誠甫' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃禮林', '教授', d.id, 'IS跨文化研究、IT組織影響、IT領導力、CIO-CEO Relationship、數位學習', '', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T86015&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃禮林' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊曉琳', '副教授', d.id, '財務實證分析、公司理財、企業併購', '國科會計畫：董事會專業性、永續發展與綠色創新（115學年度）；專利訴訟是創新的煞車還是油門？—資金成本、外部融資與現金持有之調節效果（115學年度）；企業綠色創新與氣候變遷之影響關係：以碳排放為例（113學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T09047&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊曉琳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張寶蓉', '副教授', d.id, '策略管理、國際企業管理、創新與創業、產業與競爭分析', '產學合作計畫：福壽官網產品文案撰寫與行銷活動諮詢顧問專案計畫（2021）；智微科技社群經營計畫諮詢顧問專案計畫（2021）；福壽實業商品推廣計畫諮詢顧問專案計畫（2020）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T98399&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張寶蓉' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王智弘', '副教授', d.id, '行銷管理、贊助鏈結行銷、品牌管理、數位廣告管理', '國科會計畫：探討AI代言人揭露與廣告訴求對廣告效果的影響（115學年度）；探討消費者對真人與AI代言人購買意圖之影響因素: 雙元一致性角度（115學年度）；探討奢侈品牌廣告中真人與虛擬影響者對消費者購買意圖的研究（114學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T03078&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王智弘' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳如娟', '副教授', d.id, '企業資訊系統、雲端運算服務與創新、資通訊科技服務創新、商業智慧、知識管理', '國科會計畫：從語法實作到思維調控：AI協作環境下認知卸載、負荷組態重分配與後設監控機制之探討（115學年度）；整合異質製程數據與隱性知識之混合智能決策支援系統：碳鋼管產線雙軸轉型架構之發展（114學年度）；AI發展驅動的資訊教育轉型：人工智慧與資訊領域課程內容發展與產業人才需求之探討（114學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T02178&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳如娟' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '仇介民', '副教授', d.id, '研發與創新管理、資訊科技治理、策略科技管理、科技行銷、專案管理', '產學合作計畫：研發中心組織規劃顧問諮詢計畫（2022）；營運智慧分析師初級能力鑑定考科二參考指引委託案（2019）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T97092&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '仇介民' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '鄭孟育', '副教授', d.id, '社會網絡、策略管理、研究方法、人力資源、組織行為', '國科會計畫：內部CSR觀念轉變的縱向研究：透過多年期跨產業的質化洞察、跨產業個案研究和潛在成長曲線模型揭示對組織認同和工作績效的影響，以及團隊道德領導的調節作用（115學年度）；揭開工作的面紗：探討家庭對家庭工作溢出、LMX 和工作滿意度的動態影響（113學年度）；領導者–成員關係和領導者–成員交換不同結構的後設分析（112學年度）', '指導學生競賽／獲獎紀錄（官網列3筆）：指導企管研究所獲得碩士組冠軍／中區個案競賽（2010）；指導學生榮獲學生論文一等獎／中國社會學會社會網暨社會資本研究專業委員（2011）；指導學生榮獲學生優質報告／逢甲大學（2009）', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T96039&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '鄭孟育' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '武垂玲', '助理教授', d.id, 'Supply chain management、Operation Research、Decision-making management、Energy Management、Data analysis', '國科會計畫：根據客戶需求預測結果，改善快速零售中易腐產品的可持續庫存模型（115學年度）；考慮物流服務共享和智慧資訊技術採用的線上線下雙通路供應鏈網路設計（113學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T13036&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '武垂玲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王妙如', '助理教授', d.id, '人力資源管理、組織行為、雇主品牌、策略人力資源管理、家族企業', '國科會計畫：社群平台留言氛圍對Z世代職場態度影響：從眾效應的中介效果與網路平台信任程度、工作經驗的調節效果（115學年度）；大補丸還是毒蘋果？探討AI使用在不同驅動屬性下對心流狀態及內在動機之影響（114學年度）；Z世代求職者眼中的雇主價值主張與求職意圖-雇主品牌權益觀點（114學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T11166&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王妙如' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡汶君', '助理教授', d.id, '財務管理、系統動態學、運動彩券、永續', '國科會計畫：漂綠行為對企業營運績效之影響：臺灣上市櫃公司之實證研究（115學年度）；奢侈行業揭露永續行為的財務績效影響（114學年度）；永續選股策略與獲利能力之關聯性（112學年度）', '', 'https://ba.fcu.edu.tw/%e5%b8%ab%e8%b3%87%e5%85%a7%e9%a0%81/?id=T10248&unit_id=CM01', 'https://ba.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '企業管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡汶君' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李元恕', '教授', d.id, '行銷管理、消費者行為', '國科會計畫：捐1%銷售額或賣一捐一? 推廣形式、訊息框架、與心理距離對善因行銷之知覺與參與之影響（109學年度）；廣告參考價格與企業社會責任之促發效應（108學年度）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T89042&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李元恕' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '何晉瑋', '教授兼系主任', d.id, '零售品牌與定位、網路品牌社群、消費者行為', '產學合作計畫：「inooknit 在後疫情時代的品牌推廣改進與行銷策略建議」計畫（2021）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T98374&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '何晉瑋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林豐智', '教授', d.id, '策略管理、資訊管理', '', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T88002&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林豐智' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '賴文祥', '教授', d.id, '資訊系統整合、專案管理、技術商品化、科技管理、技術移轉、研究與發展管理', '', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T94026&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '賴文祥' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王婉禎', '副教授', d.id, '消費者行為、廣告與行銷', '產學合作計畫：大鵬灣國家風景區品牌視覺計畫（2024）；大鵬灣國家風景區社群行銷數據分析及行銷建議計畫（2024）；大鵬灣國家風景區影音拍攝及社群擴展計畫（2024）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T98402&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王婉禎' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '簡士超', '副教授', d.id, '品牌美學、策略行銷、文創品牌經營、國際行銷管理、關係行銷', '', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T85001&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '簡士超' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '丁美靜', '副教授', d.id, '服務行銷、策略行銷、企業社會責任', '國科會計畫：開心連結?社群網絡的距限效應與永續企業社會責任的行銷溝通對消費者行為之影響（109學年度）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T96146&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '丁美靜' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王郁彬', '副教授', d.id, '行銷管理、電子商務及網路行銷、餐旅行銷管理、服務業行銷', '產學合作計畫：大鵬灣國家風景區品牌視覺計畫（2024）；大鵬灣國家風景區社群行銷數據分析及行銷建議計畫（2024）；大鵬灣國家風景區影音拍攝及社群擴展計畫（2024）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T91190&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王郁彬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李悅端', '副教授', d.id, '敘事視覺化與訊息設計、使用者經驗研究與服務設計、設計思考', '國科會計畫：認真的遊戲：生命桌遊的共同設計研究（108學年度）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T05064&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李悅端' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李宜靜', '助理教授', d.id, '品牌意象與識別、視覺傳達、互動與服務設計、消費者生活型態與媒體、使用者介面與體驗設計、文本分析、AI設計', '產學合作計畫：大鵬灣國家風景區社群行銷數據分析及行銷建議計畫（2024）；大鵬灣國家風景區影音拍攝及社群擴展計畫（2024）；「inooknit 在後疫情時代的品牌推廣改進與行銷策略建議」計畫（2021）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T05078&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李宜靜' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '葉俊亨', '助理教授', d.id, '情意計算、行銷資料科學、使用者經驗度量、行為偵測及分析、型別辨識、數位行銷分析', '國科會計畫：應用挖掘產品關鍵屬性及客戶標籤，自動生成 AI 廣告之研究（114學年度）；基於電商GA資料，應用馬可夫鏈探討食品業者之顧客旅程地圖，並以類神經網路預測顧客價值（112學年度）；應用K-means Elbow 方法與HDBSCAN 演算法對客戶分群效果之比較 —以電商平台消費者行為分析為例（111學年度）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T01156&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '葉俊亨' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周進華', '助理教授', d.id, '數位行銷、數據分析、Python程式設計', '產學合作計畫：大鵬灣國家風景區品牌視覺計畫（2024）；大鵬灣國家風景區社群行銷數據分析及行銷建議計畫（2024）；大鵬灣國家風景區影音拍攝及社群擴展計畫（2024）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T08171&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周進華' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林建安', '助理教授', d.id, '態度改變與行銷、行銷管理、社會心理學、工商心理學、演化心理學', '國科會計畫：人工智慧與真人講者於家教服務短影音廣告中之信任與行為意圖影響（115學年度）；以社會契約理論對夥伴選擇型互惠主義的驗證：一個跨國的比較（114學年度）', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T12195&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林建安' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李律鋒', '助理教授', d.id, '內容行銷、文案撰寫、傳播敘述、大眾文化、流行音樂、創造力', '', '', 'https://marketing.fcu.edu.tw/teachers-detail/?id=T13182&unit_id=CB26', 'https://marketing.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '行銷學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李律鋒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳婉淑', '講座教授', d.id, '時間數列分析、統計計算、貝氏分析、預測', '國科會計畫：複雜相依資料之計算與統計方法及其跨域應用－複雜相依資料之計算與統計方法及其跨域應用（115學年度）；貝氏建模和預測多元時間數列（114學年度）；COVID-19疫情對家暴和性騷擾事件的統計分析（113學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T81199&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳婉淑' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李燊銘', '特聘教授', d.id, '生物統計、生態統計、中醫統計、抽樣設計、精算數學', '國科會計畫：隨機作答架構下敏感性特徵與雙變數之聯合推論與比較（115學年度）；非直接詢問下敏感性問題與其他輔助變數的推論研究（114學年度）；有伴隨變數部分同時缺失或各別缺失下迴歸參數的推論（111學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T79038&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李燊銘' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳進家', '特聘教授', d.id, '作業研究、統計', '國科會計畫：具疲勞效應之雙代理商三機台流線型排程問題之研究（115學年度）；探討具有學習日程下雙機台流線型與兩階段機台三機台組合排程問題之研究（113學年度）；多重工作類別訂單的雙(三)目標函數準則排程問題之研究（111學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T75054&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳進家' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林麗芬', '教授', d.id, '死亡率/罹病率研究、退休金精算、精算準備金議題研究、精算應用統計、極值損失建模/分析', '國科會計畫：商業保險納入安寧居家療護之定價與經濟效益研究（108學年度）', '指導學生競賽／獲獎紀錄（官網列5筆）：指導統計學應用競賽 銀獎 及 兩項佳作獎／逢甲大學（2018）；指導統計學應用競賽 佳作-優等獎／逢甲大學（2017）；指導統計學應用競賽 金獎／逢甲大學商學院/金融學院（2016）；指導統計學應用競賽 銅獎／逢甲大學商學院金融學院（2015）；指導統計學應用競賽 銅獎／逢甲大學商學院/金融學院（2014）', 'https://stat.fcu.edu.tw/teachers-detail/?id=T81067&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林麗芬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '鍾冬川', '教授', d.id, '應用隨機過程、統計譜系學、生物系統建模', '國科會計畫：共變數驅動之歐式系統發育性狀演化迴歸模型：聯合估計適應性最適值與演化速率（115學年度）；估計分子演化的速率與時間的統計建模:自回歸條件異值變異數模型（114學年度）；利用分數布朗運動和分數奧恩斯坦-烏倫貝克過程對種系發育性狀演化的統計建模（113學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T00237&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '鍾冬川' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳榮彬', '副教授', d.id, '經驗法則逼近法、空間統計、問卷設計、抽樣調查、實驗設計', '產學合作計畫：埔里全民運動館民眾需求及意願問卷調查（2025）；臺南市政府都市發展局社會住宅抽籤程式隨機性認證書（2025）；臺中市立圖書館112年度讀者滿意度調查計畫（2023）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T88009&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳榮彬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李仁佑', '副教授兼系主任', d.id, '生物統計、基因統計、時間序列分析', '國科會計畫：多類別表現型的方向性 Beta-mixture TREM方法（115學年度）；統計時間數列方法與微分方程灰模式之整合模型（114學年度）；具共變量邏輯斯模式下穩健偵測多基因與疾病關聯性方法（111學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T04246&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李仁佑' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉峰旗', '副教授', d.id, '財務計量方法、貝氏分析、統計計算、商業分析', '國科會計畫：有序時間序列模型於股價報酬率區間預測之應用（115學年度）；長照車隊數位大聯盟-無障礙交通接送公自費預約媒合平台研發與推廣（114學年度）；具零壹膨脹的設限計數型時間序列之貝氏建模（112學年度）', '指導學生競賽／獲獎紀錄（官網列4筆）：指導統計學應用競賽 金獎／逢甲大學商學院/金融學院（2019）；指導統計學應用競賽 佳作／逢甲大學商學院/金融學院（2018）；指導統計學應用競賽 銅獎／逢甲大學商學院/金融學院（2018）；指導統計學應用競賽 銀獎／逢甲大學商學院/金融學院（2018）', 'https://stat.fcu.edu.tw/teachers-detail/?id=T97010&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉峰旗' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '盧馬汀', '副教授', d.id, '缺失數據與測量誤差、非參數和半參數模型、零值過多的計數數據、交通事故數據分析、社交網絡分析的統計方法', '國科會計畫：進階應用兩階段隨機作答於收入調查設計及收入迴歸的分析方法（114學年度）；柵欄模型與不完整共變異數的零膨脹模型在交通及醫療領域的應用（112學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T12196&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '盧馬汀' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '巫亮宏', '助理教授', d.id, '大數據與人工智慧、高維度統計資訊視覺化、統計分析', '國科會計畫：人工智慧推薦系統中性別公平性之研究（115學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T09029&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '巫亮宏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王俞凱', '助理教授', d.id, '時間數列分析、貝氏推論、數理統計、迴歸分析', '國科會計畫：以 Copula 為核心之非線性相關建模方法：動態分析與多變量推廣（115學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T15033&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王俞凱' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '廖揚立', '助理教授', d.id, '製程監控、集群分析、統計學習', '國科會計畫：國內航空網路之樞紐演變分析：以澳洲為例(1984-2019)（115學年度）；整合LASSO算法與跨欄模型於零膨脹資料及其應用之研究（114學年度）；改良的耦合型累積和方法在監控自相關過程之研究（112學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T11091&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '廖揚立' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '杜昌燁', '助理教授', d.id, '財務工程、機器學習、作業研究、科學計算', '', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T14160&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '杜昌燁' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '賴暐婷', '助理教授', d.id, '貝氏分析、時間序列、變數選擇', '國科會計畫：高維矩陣自迴歸模型中的變分貝氏推論（115學年度）', '', 'https://stat.fcu.edu.tw/teachers-detail/?id=T14033&unit_id=CB07', 'https://stat.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '統計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '賴暐婷' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蕭堯仁', '講座教授', d.id, '工業工程與管理、資源規劃與配置、供應鏈績效與管理、專案導入績效與管理、產業電子化分析與規劃、品質工程、預防維護與保養管理', '國科會計畫：分析及建立碳排放異常/維護衝突之動態預防維護規劃（114學年度）；分析及建立前沿技術趨勢演化分析之機制（111學年度）；分析與建立網絡生產系統之多目標動態循環預防維護規劃（111學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T80041&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蕭堯仁' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林棋瑋', '教授兼系主任', d.id, '產品設計與研發管理', '國科會計畫：基於 YOLO 與 IoT 之數位 Poka‑Yoke 工位級手工具防 FOD 收納系統（115學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T96196&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林棋瑋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '唐國豪', '教授', d.id, '人機介面互動設計、人因工程、認知工程與介面設計、生產與作業管理', '國科會計畫：以深度學習提升協作型機器人在「人-機器人協作」組裝環境下之遞交作業流暢度及主觀滿意度（110學年度）；人與機器人協作環境下最短可接受靜態及動態距離之建立（108學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T84003&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '唐國豪' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王逸琦', '教授', d.id, '精實製造/精實企業系統、供應鏈管理、系統模擬、製造程序', '國科會計畫：工具機鑄件運輸之車輛路徑問題（112學年度）；工具機鑄造廠木模取放與搬運之改善（110學年度）；建構工具機產業之循環經濟模式（109學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T93146&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王逸琦' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林暘桂', '教授', d.id, '生產排程、最佳化、作業研究、系統模擬、實驗設計、統計', '國科會計畫：多訂單工件排程問題於平行機、彈性流程式、及彈性零工式生產環境之全面探討與應用（115學年度）；考慮可重複使用醫療器材滅菌與醫生之跨日連續排程問題（115學年度）；考慮不相容工件族具設置時間和釋放時間的平行機串行批量處理之排程問題（113學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T97041&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林暘桂' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊士霆', '副教授', d.id, '資料探勘、巨量資料分析、商業智慧、知識管理、企業電子化、行動商務', '國科會計畫：基於LLaMA 4模型應用於社群輿情資料之議題趨勢與評論生成模式（115學年度）；以LLaMA 3模型與Myers演算法之程式碼版本更動與註解生成模式（114學年度）；基於LLaMA3模型個人化電子郵件回覆生成模式（114學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T06239&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊士霆' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳兆衡', '副教授', d.id, '永續製造、科技管理、企業永續管理、EMI 課程', '國科會計畫：無人化資源回收系統之建置（111學年度）；影像識別塑膠回收指示系統（111學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T08188&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳兆衡' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '鍾健平', '副教授', d.id, '生產與作業管理、品質經營管理、企業資源規劃、智慧生產與系統整合、系統動力學', '', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T97094&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '鍾健平' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周哲維', '副教授', d.id, '智慧製造、決策分析、工程資料分析與最佳化、系統模擬、智能營運', '國科會計畫：整合電腦視覺與大型語言模型之智能機械手臂堆棧系統之研究（115學年度）；砂模鑄造製程參數最佳化之研究（115學年度）；射出成形機新產品試作製程參數組合最佳化（114學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T10242&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周哲維' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '丘紀堇', '副教授', d.id, '應用藝術與設計、創意研發', '產學合作計畫：新材實業有限公司廢棄不織布的永續創新應用研究（2026）', '指導學生競賽／獲獎紀錄（官網列7筆）：指導國際科技與管理學院同學參與105學年度第2學期創新專題課程之成果發表競賽獲獎／逢甲大學（2017）；指導企管系、國企系、財稅系、纖複系、行銷系同學參加逢甲大學鞋類產業人才學分學程105學年度第1學期核心課程之靜態成果展票選活動，榮獲鞋類設計與製造組第一名、第二名、第三名及佳作／逢甲大學（2016）', 'https://inde.fcu.edu.tw/teachers-detail/?id=T99056&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '丘紀堇' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡麗珍', '助理教授', d.id, '人因工程、人機介面與人機互動、資料庫設計、專案管理', '產學合作計畫：精密機械加工之精實生產改善II（2026）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T90076&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡麗珍' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周育樂', '助理教授', d.id, '先進製程控制、生產及排程最佳化、供應鏈規劃及管理、智慧製造', '國科會計畫：結合貝式最佳化與結構剪枝輕量化之異質圖神經網路組合最佳化研究:應用於具多交期的多目標Flexible Job Shop排程（115學年度）；強化供應鏈韌性及適應性：考慮未知偏好下之多準則智慧決策方法（112學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T10247&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周育樂' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '伍廷蔚', '助理教授', d.id, '人工智慧與機器學習、深度學習與資料探勘、大數據分析與決策支援、可解釋式人工智慧與預測建模、效率評估與多準則決策分析、智慧製造與工業資料分析', '', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T15034&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '伍廷蔚' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王履梅', '助理教授', d.id, '數位轉型策略規劃、資訊系統規劃分析、資訊服務精實創新、商業智慧與數據分析、專案管理、資訊管理', '國科會計畫：建置台灣上市櫃企業之永續商業資訊：永續漂綠指標與氣候空話指標（115學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T86010&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王履梅' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '莊文傑', '助理教授', d.id, '創新管理、資訊管理、電子商務與企業電子化、企業智慧', '國科會計畫：新興科技創新營運模式－台灣智慧製造創新營運中心-總計畫及子計畫二、四、五（108學年度）', '', 'https://inde.fcu.edu.tw/teachers-detail/?id=T90073&unit_id=CE06', 'https://inde.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '工業工程與系統管理學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '莊文傑' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊文祿', '特聘教授', d.id, '半導體物理及元件、超大型積體電路設計及技術', '國科會計畫：全光領域操控光儲存系統以及高功能憶阻陣列之研發（114學年度）；高效能電阻式光記憶體研發以及內嵌光記憶薄膜的新穎電荷擷取式記憶體之研究（111學年度）；聚亞醯胺薄膜經 UVB 光照射後其元件特性與其應用於記憶體元件之研究（110學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T81206&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊文祿' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '施仁斌', '特聘教授', d.id, '電子材料、奈米科學、薄膜工程、固態物理、太陽電池、鋰電池、氣體感測器', '國科會計畫：開發新型具徑向異質接面核殼/單質熱電奈米線與陣列的技術與熱電優值研究-未來應用於廢熱再生能源（111學年度）；通過電化學沉積技術-開發三元化合物半導體之薄膜及奈米線之太陽光電池應用於未來節約能源（109學年度）；電化學法合成三元化合物半導體之太陽光電應用於未來節約能源（108學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T81038&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '施仁斌' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李景松', '特聘教授', d.id, '半導體物理、化合物半導體高速元件、有機發光二極體、有機太陽能電池', '國科會計畫：III族-氮化物異質結構場效電晶體及其紫外光感測應用之技術開發（115學年度）；新型含鈧III族-氮化物異質結構場效電晶體設計之技術開發（114學年度）；新型具有P型通道III族-氮化物異質結構場效電晶體設計之技術開發（113學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T91151&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李景松' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉堂傑', '教授', d.id, '積體電路設計、顯示器驅動技術、高速元件、數值計算', '國科會計畫：基於 U-Net 深度學習之腰椎X光影像結構分割與骨質功能性指標自動化量測之疾病預測系統開發（115學年度）；環口牙片自動化恆牙乳牙定位結合編號演算法與阻生牙辨識（114學年度）；穿戴式裝置之癲癇預警偵測（111學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T83083&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉堂傑' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '簡鳳佐', '教授', d.id, '功率元件、光電元件、薄膜電晶體、Ⅲ-Ⅴ化合物半導體/高速電子元件、半導體製程與半導體元件特性模擬', '國科會計畫：側壁佈植載子儲存層絕緣閘極雙極性電晶體（115學年度）；提升短路耐受時間之載子儲存層與浮動P柱絕緣閘雙極性電晶體（113學年度）；多重浮接 P 型深溝槽氧化柱之溝槽式高導電度絕緣閘雙極性電晶體設計（112學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T88076&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '簡鳳佐' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林宗志', '教授', d.id, '類比積體電路測試、混合積體電路設計、控制系統分析與設計、強健控制、模糊與類神經系統分析與設計', '國科會計畫：道路潛在危險行為預測之次世代行車助理系統－道路潛在危險行為預測之次世代行車助理系統（111學年度）；智慧型第一型糖尿病人血糖調節之飲食識別與計算之嵌入式設計與實現（111學年度）；第一型糖尿病人智慧型血糖濃度調節硬體迴路測試平台之實現暨可靠度分析（110學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T77045&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林宗志' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '康宗貴', '教授', d.id, 'IC製程技術開發 薄膜電晶體設計', '國科會計畫：不同界面層超晶格氧化鋯鉿(HfZrO₂)薄膜結合界面電漿處理之奈米元件閘極介電層特性研究（115學年度）；不同種子層對氧化鋯鉿雙疊層薄膜電容結構之鐵電特性研究（114學年度）；調整鋯原子比例之氧化鋯鉿反鐡電薄膜疊層應用於記憶體與低溫量子計算之特性研究（113學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T90121&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '康宗貴' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '鄭經華', '教授', d.id, '超大型積體電路設計、超大型積體電路測試、超大型積體電路電腦輔助設計', '國科會計畫：具效能可調整與容雜訊干擾的二維陣列光達系統晶片之設計與驗證（114學年度）；單光子崩潰二極體陣列主動像素感測器探究與實現（114學年度）；應用在生物醫療上的高精度光學感測系統設計（113學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T92024&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '鄭經華' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林成利', '教授', d.id, '半導體製程技術、半導體元件物理、元件量測技術及可靠度研究、新型記憶體元件技術', '國科會計畫：應用於碳化矽元件之氧化鋯閘極高介電層特性研究（114學年度）；新穎氮化鈧鋁(AlScN)高介電與鐡電閘極介電層薄膜之碳化矽場效電晶體元件特性研究及其應用於高溫與記憶體特性探討（113學年度）；不同閘極金屬氮化鋁鈧(AlScN)鐵電薄膜應用於鐡電記憶體之特性研究（113學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T96058&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林成利' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林進發', '教授', d.id, '低功率電路設計、超大型積體電路設計、人工智慧感測與控制系統', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T15008&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林進發' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊炳章', '副教授', d.id, '半導體物理及元件、積體電路、絕緣物上矽晶技術', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T81219&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊炳章' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '許恒壽', '副教授', d.id, '類比積體電路設計與模擬、高速信號傳輸、雷射二極體驅動電路、類比濾波器設計', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T95212&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '許恒壽' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王通温', '副教授', d.id, 'TCAD結構模擬、砷化鎵、磷化銦、氮化物半導體材料成長、ADS高頻電路設計、光學半導體、IoT 物聯網應用與影像人工智慧、ESP、Jason nano嵌入式應用', '國科會計畫：極低功耗的穿隧式鰭式電晶體之特性研究 Ultra Low Power Tunnel FINFET Characteristics Research（115學年度）；T型閘極氮化鋁銦 HEMT與0.12μm GaN多極LNA電路太赫茲元件研發（114學年度）；基於TCAD模擬之多通道階梯狀FinFET在不同應力條件下的電性分析（114學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T08057&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王通温' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王馭熊', '副教授兼系主任', d.id, '奈米先進製程導論、三維積體電路、嵌入式記憶體', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T11046&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王馭熊' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張一楠', '助理教授', d.id, '微機電系統、光纖感測、半導體製程', '國科會計畫：二輪機動車輛自動防傾倒輔助系統（114學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T84031&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張一楠' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '何家淮', '助理教授', d.id, '半導體元件設計、製程與模擬、半導體特性曲線量測、模擬與分析、單晶片原理與應用、專案管理、系統工程與分析', '國科會計畫：FinFET元件通道材料與雜質摻雜對操作性能影響之研究（113學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T12036&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '何家淮' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳宗毅', '助理教授', d.id, '數位晶片設計、系統單晶片(SoC) 設計、硬體加速器設計、影像處理、人工智慧', '國科會計畫：基於非侵入式心肺功能早期檢測與長期追蹤應用之人工智慧評估系統與邊緣運算硬體實務設計（115學年度）；基於足部影像形態特徵之肺活量預測模型與FPGA實作（115學年度）；整合形態學影像增強與YOLO26之ICE淋巴管術前輔助偵測系統（115學年度）', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T12040&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳宗毅' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '許騰仁', '助理教授', d.id, '數位積體電路設計、生醫信號處理、類神經網路、嵌入式微處理系統與應用', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T13145&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '許騰仁' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉維正', '助理教授', d.id, '無線通訊', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T11220&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=3', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉維正' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊鎮安', '講師', d.id, 'IC設計、電子學、數位IC設計、電子設計自動化、人工智慧、電腦視覺、演算法', '', '', 'https://fcuece.fcu.edu.tw/teachers-detail/?id=T12310&unit_id=CE09', 'https://fcuece.fcu.edu.tw/faculty/?post_page=3', '2026-11-11'
FROM departments d WHERE d.name = '電子工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊鎮安' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '邱創乾', '講座教授', d.id, '語音識別、影像處理、電腦輔助醫學診斷、生醫訊號處理', '國科會計畫：利用加速度計開發智慧枕於睡姿與睡眠品質之自動偵測研究（115學年度）；利用雙通道電子奶嘴與生理參數發展早產新生兒吸吮能力與能量消耗之綜合量化評估系統（114學年度）；基於語音及手勢辨識發展自動視力檢測系統（114學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T82007&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '邱創乾' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林賢龍', '特聘教授', d.id, '生醫控制系統、呼吸控制與臨床應用、腦血流調控與臨床決策支持系統、生醫訊號處理', '國科會計畫：基於性別差異分析的糖尿病患者腦血流調控的非線性評估（L03）（113學年度）；結合Canny邊緣檢測與Deepsort影像辨識方法應用無人機於自動追蹤移動物件（113學年度）；從性別角色分析姿勢性直立心搏過速症候群的腦血管對二氧化碳反應與臨床監測輔助平台建置 (L03)（112學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T81135&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林賢龍' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪三山', '特聘教授', d.id, '電子電路設計、感測系統訊號分析與設計、強健控制、車用電子電路設計', '國科會計畫：透過加速規與CoreXY架構配重平台實現重心穩定系統之研究（115學年度）；以應變計及加速規實現動態平台即時監控系統（114學年度）；具環境多元感測與監控機制之智慧化曬衣系統（113學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T74002&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪三山' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林昱成', '特聘教授', d.id, '智慧型控制、最佳控制、強健控制、車輛影像安全輔助系統、嵌入式系統、深度學習、生成式AI', '國科會計畫：AI驅動農業機器人（115學年度）；融合認知神經科學與視覺語言模型之擬人腦智慧決策與控制系統開發與驗證（115學年度）；具身智慧賦能：結合視覺語言動作模型與純視覺3D動態場景理解之自駕堆高機與智慧倉儲系統（115學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T02182&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林昱成' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '鄒慶福', '教授', d.id, '微機電系統、微結構力學、微系統封裝力學', '國科會計畫：新型微光機電系統麥克風晶片之設計與製造（115學年度）；基於矽基氮化鎵磊晶片之光邏輯閘的設計與製作（115學年度）；智慧型三指仿人投球機械手臂之系統開發（115學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T90006&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '鄒慶福' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉益瑞', '教授', d.id, '醫用磁振影像、醫學影像處理、生醫信號處理、3D生物列印', '國科會計畫：以特徵調和與聯邦學習優化自動機器學習放射影像組學模型架構：跨資料庫驗證與可解釋人工智慧研究（115學年度）；以自動機器學習與聯邦學習優化穩定性與泛化性的放射影像組學模型：跨資料庫驗證研究（114學年度）；以2D空間選擇射頻和MUSE技術發展高解析度擴散磁振影像應用於硬腦膜淋巴系統的監測（113學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T93009&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉益瑞' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林育德', '教授', d.id, '生醫信號處理、生醫感測系統設計、MCU-Based 嵌入式系統、數位信號處理、智慧型信號處理、機器學習、深度學習、邊緣運算', '國科會計畫：基於多任務學習的單導程心電圖異質生理參數估測變形網路之研發及其邊緣運算應用於圍手術期低血壓風險示警的可行性評估（115學年度）；基於單一模態生醫信號之異質生理參數估測的多任務管線神經網路設計與雲端部署（114學年度）；異質生理信號的感壓反射靈敏度變形網路模型開發及其臨床應用（113學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T90141&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林育德' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '沈祖望', '教授', d.id, '生醫工程、光聲影像、人工智慧、智慧感測裝置、仿生智能、實境技術整合', '國科會計畫：基於膜計算與蟻群優化的多現場可程式化邏輯閘陣列自適應生醫影像/訊號處理架構（115學年度）；以可程式化邏輯結合生理訊號實現仿生晶片控制:以警用戰略犬為例（115學年度）；以鼾聲為核心技術之兩通道生理訊號智慧枕實現阻塞性呼吸中止手術之評估與預測（114學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T07043&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '沈祖望' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林南州', '副教授', d.id, '機器人學、仿生控制、系統模擬', '國科會計畫：以VLM驅動之葡萄果園語意理解與自動套網作業機器人（115學年度）；基於太陽運行軌跡實現太陽能電板追日發電優化之研究（114學年度）；基於聲音辨識之管道內部智慧檢漏系統（113學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T81207&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林南州' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳鏡崑', '副教授', d.id, '生醫訊號與資訊安全加密、混沌編碼、電子電路應用', '國科會計畫：基於機器學習與多感測器融合之AI智慧可變色溫與轉向照明車燈系統（114學年度）；基於智慧視覺辨識之自助式垃圾與回收分類系統（112學年度）；移動物體感測定位之月台無障礙系統（111學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T01163&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳鏡崑' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '廖本義', '副教授兼系主任', d.id, '醫學工程、生醫訊號處理分析、生物力學', '國科會計畫：結合多頻生物電阻抗、動作控制與超音波影像之多模態熵分析於肌少症複雜度指標建立與早期檢測之研究（115學年度）；AI行人守護者:結合YOLO物件偵測與AR抬頭顯示之智慧穿戴式道路風險預警系統（115學年度）；主動式騎乘機車安全輔助系統之開發（114學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T95056&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '廖本義' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳志成', '副教授', d.id, '智慧感測器融合的多模態系統、運用機器學習及深度學習於工廠自動產線AOI 瑕疵檢測、智慧機器人步態控制演算法、AI智慧滾動軸承監測和故障診斷、智慧載具運動軌跡控制系统', '國科會計畫：高噪聲工業聲學健康監測之無監督異常偵測：以 WGAN-GP 為核心之生成式學習方法（115學年度）；結合AI智能補焊與雷射能控技術之TPMS智慧產線建置計畫（114學年度）；基於頻率域注意力與小波卷積融合的深度學習網絡:軸承故障診斷新方法（114學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T09242&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳志成' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '秦群立', '副教授', d.id, '人工智慧、嵌入式系統、醫學影像處理、圖形識別、系統分析與設計', '國科會計畫：基於可解釋性架構於外傷性與自發性顱內出血之影像辨識方法（115學年度）；結合人因工程目標之深度學習視覺伺服智慧控制系統於聽覺障礙輔具之研製（115學年度）；整合多模型之智慧箱尺量測系統（114學年度）', '指導學生競賽／獲獎紀錄（官網列1筆）：第26屆旺宏金矽獎---銅獎(指導教授)／財團法人旺宏教育基金會; 旺宏電子股份有限公司（2026）', 'https://auto.fcu.edu.tw/teachers-detail/?id=T98318&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '秦群立' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '徐永煜', '副教授', d.id, '圖形識別、影像分析與處理、類神經網路、深度學習、智慧醫療、智慧感測與人工智慧應用', '產學合作計畫：AI賦能數位雙生電力調度平台開發計畫（2026）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T14154&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '徐永煜' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝男凱', '助理教授', d.id, '機械智慧製造、物聯網應用、機電整合、機械手臂實務', '國科會計畫：應用正交投影變換融合與ARV-ResNet並整合多源訊號於提升諧波減速機健康診斷準確率（114學年度）；結合遷移式學習與嵌入式系統於機械手臂即時故障預測與健康管理系統（113學年度）；基於Shape-based Matching影像辨識方法結合工業CCD於偵測IC擺放姿態（113學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T10239&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝男凱' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林上智', '助理教授', d.id, '人工智慧、最佳化理論、智慧製造、無人載具', '國科會計畫：基於強化式學習模式的CNC工具機鏟花策略設計（115學年度）；基於火情多模態感測模型的無人飛行載具巡檢與應變系統（114學年度）；基於校園5G網路的無人載具智慧裝箱與配送應用（114學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T10240&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林上智' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃清輝', '助理教授', d.id, '人工智慧輔助外形參數化設計、無人載具影像識別最適化運動路徑研究、血管特性精密量測研究、數位智能工廠及機電整合測試', '國科會計畫：深度學習融合影像定位之GPS盲區無人機自主避障飛行路徑前瞻技術研究（115學年度）；卷積神經網絡影像定位實現於室內無GPS智慧停車場路徑導航（115學年度）；類神經演算影像定位運用於定翼無人機GPS盲區飛行路徑實現（114學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T10275&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃清輝' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉承勳', '助理教授', d.id, '微機電系統製程技術、微機電系統設計、元件封裝', '國科會計畫：應用於光學測試之主動式氮化鎵探針卡（115學年度）；具有動態感測之防傾倒輔助車輪模組（114學年度）；矽中介層與氮化鎵光學引擎之整合研究（113學年度）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T10279&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉承勳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李峰吉', '助理教授', d.id, '伺服控制系統、機電整合、自動控制、多軸運動控制、馬達控制', '產學合作計畫：控制平台類比電壓命令測試與驗整模組（2026）；無人機飛控控制於動力系統延遲測試與驗證報告（2026）', '', 'https://auto.fcu.edu.tw/teachers-detail/?id=T15029&unit_id=CE12', 'https://auto.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '自動控制工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李峰吉' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '彭嘉美', '教授', d.id, '天線設計、濾波器設計、射頻電路設計、SAR(電磁能比吸收率)量測與對策分析、RFID系統設計、電磁輻射量測及人機介面程式控制', '國科會計畫：有限接地面下天線接地電流導引與重新分配設計：輻射效應、高速傳輸路徑時域穩定度與中介表徵之系統層指標量化研究（115學年度）；二維微帶陣列去耦合設計/Decoupling design of two-dimensional microstrip arrays（115學年度）；B5G/6G 微波/毫米波之智慧型穿戴式裝置小型化HMSIW天線設計與低SAR研究（113學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T07045&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '彭嘉美' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陸清達', '教授', d.id, 'AIoT應用與系統整合、人工智慧應用、數位音訊處理、數位影像處理', '國科會計畫：智慧視覺之聽損輔助系統實現（115學年度）；應用多光譜深度學習於皮秒雷射臉部斑點輔助辨識之研究（115學年度）；結合多模態神經網路與仿生材料之超音波醫美治療成效預測（115學年度）', '指導學生競賽／獲獎紀錄（官網列1筆）：2025 逢甲大學科技創新應用競賽，榮獲「指導貢獻獎」／逢甲大學（2025）', 'https://ce.fcu.edu.tw/teachers-detail/?id=T11165&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陸清達' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '袁世一', '教授', d.id, '嵌入式系統設計、即時嵌入式作業系統、驅動程式設計、IC電磁相容模型', '國科會計畫：無人航空載具之建築外牆磁磚瑕疵智慧檢測系統設計與開發（113學年度）；EMI-leakage platform design（112學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T93053&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '袁世一' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡淵裕', '教授兼系主任', d.id, '多媒體安全、計算機圖學、影像處理', '國科會計畫：融合頂點索引值相似性、視角感知與建構式幾何處理的加密三維模型可回復式資訊隱藏技術（115學年度）；植基於體素相似性估計之加密三維體積資料可回復式資訊隱藏技術（115學年度）；基於索引局部性強化與最短模差建構之三維模型頂點索引秘密分享技術（115學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T12037&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡淵裕' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊豐瑞', '副教授', d.id, '網路通訊、平行處理、人工智慧', '國科會計畫：結合5G無人機與多模態生成式AI建立交通事故3D還原系統之研究（115學年度）；結合5G無人機與多模態生成式AI於道路事故現場語意分析與自動化報告生成之研究（115學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T82107&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊豐瑞' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '辛正和', '副教授', d.id, '數位影像處理、數位訊號處理、電腦視覺、視訊編碼、機器學習、深度學習、色彩工程、照相機成像機制', '國科會計畫：無線AI聽損智慧帽之實現（115學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T83008&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '辛正和' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '尤正祺', '副教授', d.id, '射頻及微波電路、天線、微波介電材料', '國科會計畫：多頻高隔離度5G手機MIMO天線（113學年度）；應用於筆記型電腦之小型Wi-Fi 6E MIMO天線陣列（113學年度）；應用於5G行動裝置之Sub-6GHz頻段天線陣列（108學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T93181&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '尤正祺' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '趙啟時', '副教授', d.id, 'AI賦能之網路管理系統研發、網路管理自動化代理人研發、主從協同之邊緣網管計算系統研發、網路攻防之智能化與程式設計', '國科會計畫：基於多模態特徵融合與時空關聯分析之隱蔽性攻擊檢測系統（115學年度）；融合多維度數據與流量資料分析之網路安全韌性強化工具開發與實作（114學年度）；在大規模網路攻擊下具高存活率之防火牆規則平行最佳化系統之研發與實作（111學年度）', '指導學生競賽／獲獎紀錄（官網列1筆）：逢甲大學科技創新應用競賽【優選佳作】指導貢獻獎／逢甲大學（2025）', 'https://ce.fcu.edu.tw/teachers-detail/?id=T87092&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '趙啟時' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳益生', '副教授', d.id, '通信信號處理、多輸入多輸出系統、無線通訊', '國科會計畫：自走式智慧循跡導航病床系統之開發（115學年度）；結合5G無人航空載具與生成式AI之禽類流感智慧檢測系統設計與開發（114學年度）；循環延遲多樣性之多輸入多輸出單載波頻域等化系統下的盲通道估測:以週期性預編碼為基礎（112學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T96034&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳益生' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林維崙', '副教授', d.id, '通訊系統信號處理、未來世代通訊系統、人工智慧系統、機器人系統、深度學習、物聯網系統', '國科會計畫：基於電腦視覺與大聯盟 Statcast 數據之棒球外野飛球落點預測與輔助訓練系統研發（115學年度）；智慧游泳訓練輔助系統（114學年度）；應對通道不確定性的次世代無線通訊系統等化方法研究（114學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T00227&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林維崙' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳家豪', '副教授', d.id, '射頻積體電路設計、類比積體電路設計、微波元件與電路設計、元件模型與可靠度分析', '國科會計畫：在 GNU Radio 實現基於深度學習的 OFDM 接收機（115學年度）；應用於5G通訊之雙核壓控振盪器晶片設計之研究（113學年度）；基於臉部感知隱私保護資料收集及低功耗晶片設計（112學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T04063&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳家豪' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡昂勳', '副教授', d.id, '6G行動通訊網路、無人機通訊網路、低軌衛星通訊網路、AI驅動之通訊系統、整合感測與通訊技術、無線資源管理', '國科會計畫：整合暗通道視覺與5G無人機之三維PM2.5智慧監測研究（115學年度）；適用於無人航空載具之人體影像骨架跌倒偵測系統設計與開發（112學年度）', '指導學生競賽／獲獎紀錄（官網列24筆）：指導大學部學生參加「2026智慧創新大賞(Best AI Awards)」，榮獲「AI應用類學生組」佳作（2026）；參加「2025教育部跨域晶片設計應用創新專題實作競賽」，榮獲智慧環境類組入選獎（2025）；參加「2025 逢甲大學科技創新應用競賽」，榮獲數位應用類創新銅獎（2025）；參加「2024第29屆大專校院資訊應用服務創新競賽(InnoServe 2024)」，榮獲資訊應用組入圍決賽（2024）；參加「2024中華電信5G創新應用大賽」，入圍決賽（2024）', 'https://ce.fcu.edu.tw/teachers-detail/?id=T09182&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡昂勳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '朱嘯秋', '助理教授', d.id, '數位通訊、無線網路、偵錯編碼', '國科會計畫：Image scrambling with pseudo random patterns from direct-sequence-generating（112學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T89186&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '朱嘯秋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '呂威甫', '助理教授', d.id, '無線感測器網路的演算法、生物資訊學的機器學習、生物資訊演算法、演算法設計與分析、離散數學', '國科會計畫：幾何感測網路中滿足覆蓋與連通限制之路由近似分析（115學年度）；基於生成式AI與CSRNet 之5G無人航空載具人群密度即時監測系統設計與開發（114學年度）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T12172&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '呂威甫' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '何子豪', '助理教授', d.id, '電源/訊號(PI/SI)完整性、射頻干擾RFI、Package SI/PI 設計、ICEMC 積體電路EMC測試技術', '產學合作計畫：智慧車電產品傳導干擾CE模擬分析研究（2026）；2026 IEC 61967-4 150ohm積體電路電磁模擬平台架設計畫（2026）；應用於無人機電源管理積體電路電磁干擾研析與抑制-電源與記憶體模組電磁雜訊耦合技術研析（2026）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T10278&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '何子豪' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝瑞民', '助理教授', d.id, '演算法、資料庫系統、數值分析', '', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T07140&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝瑞民' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳紀翰', '助理教授', d.id, '人工智慧感測系統、遙測電腦視覺與語意分析、邊緣與嵌入式人工智慧系統架構設計、智慧訊號處理與多模態感測整合、節能化 AI 加速與裝置端最佳化', '產學合作計畫：多節點AI視覺感測之固定排放源監控系統開發與維護（2026）；裸露地影像AI辨識作業（2026）', '', 'https://ce.fcu.edu.tw/teachers-detail/?id=T14178&unit_id=CI02', 'https://ce.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '通訊工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳紀翰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李秉乾', '特聘講座', d.id, '土木工程、耐震補強、防災監測、材料力學', '國科會計畫：國際淨零技術生態創新聯盟（114學年度）；大規模崩塌地之破壞機制、災害預警及風險評估之先進研究-利用多元時空大數據特徵與深度學習模式於探索廣域崩塌發生可能性之研究(子計畫六)（109學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T83001&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李秉乾' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林保宏', '教授', d.id, '營建管理、工程品質管理、工程風險管理與決策分析、專案管理、BIM營建資訊模擬', '產學合作計畫：112-113年度「公有危險建築補強重建-公有零售市場」委託專案管理（2023）；BIM塑模及VR虛擬實境導覽系統之應用研究（2022）；嘉義縣推動工程資訊模型(EIM)規劃委託專業服務案（2021）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T90074&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林保宏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林正紋', '教授', d.id, '結構工程、自動控制、工程管理、電腦輔助設計、人工智慧', '產學合作計畫：工程零碳建設技術導入與財稅實務推動計畫（2025）；結合崩塌機率模式與BigGIS系統發展震後坡地崩塌之評估（2022）；智慧營建 深耕土木 永續防災（2021）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T94051&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林正紋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張智元', '教授', d.id, '建築醫學、社會住宅、營建管理、營建法規與實務、智慧物業管理、健康環境規劃、醫學工程', '國科會計畫：利用CFD模擬室內流場之最適環境改善策略-以居家焚香污染為例（111學年度）；以職業醫學為基礎之營建勞工聽力損害預警系統研發（110學年度）；時間序列導入先行指標因子(股價)之用電預測模型分析與比較（109學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T96054&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張智元' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林威延', '副教授', d.id, '地理資訊系統、營建管理、工程資訊管理、空間資訊整合應用技術、建築資訊塑模、三維地理資訊系統', '國科會計畫：應用人工智慧於BIM工程圖尺寸標註與圖面配置最佳化技術開發（115學年度）；應用檢索增強生成（RAG）技術建構營建工程教科書知識型 Chatbot 之初探研究（115學年度）；應用大型語言模型(LLM)、BIM與Chatbots於工程圖說資訊檢索之研究（113學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T99121&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林威延' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '紀昭銘', '副教授', d.id, '基礎工程與其在大變形下之塑性分析、土壤動力、大地工程之數值分析、海洋石油工程地錨之分析、透地雷達', '國科會計畫：軟弱土層拋石擠壓置換模擬與拋石堤承載力評估方法驗證研究（114學年度）；軟弱土層拋石防波堤建置拋石量與承載力評估研究（113學年度）；藉由keying過程以提升海洋板錨之極限錨定力（112學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T06200&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '紀昭銘' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '賴哲儇', '副教授', d.id, '遙感探測、地理資訊系統、機器學習、自然資源與災害模式化、數值地形與智慧城市', '國科會計畫：主題式-建構都市森林碳匯數位孿生平台:基於IPCC Tier 2a/2b之精準核算路徑（115學年度）；基於無人機調查與測繪之大面積森林蓄積量推估研究 -結合空載光達與多光譜影像（113學年度）；從潛勢評估觀點探討主被動式遙測資料結合機器學習偵測崩塌範圍及建置目錄之盲點和精進（112學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T07036&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '賴哲儇' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '莊財福', '副教授', d.id, '鋼筋混凝土、鋼結構、工程材料與力學、結構學、材料力學、應用力學、結構動力學、塑性力學、有限元素法、電腦輔助設計、ACAD、3DMax、景觀設計', '國科會計畫：自調適複材橡膠隔震器於巨木結構之應用（110學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T08196&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '莊財福' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林喻峰', '副教授兼系主任', d.id, '非破壞檢測技術、鋼筋混凝土、結構力學實驗、電腦輔助工程、橋梁工程', '國科會計畫：應用微鑽孔試驗法評估混凝土受火害後之劣化程度（114學年度）；人工智慧在輔助辨識透地雷達回波訊號之成效評估（113學年度）；混凝土碳封存技術成效之探討與對工程性質之影響評估（113學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T12039&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林喻峰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '曾韋禎', '助理教授', d.id, '土壤力學、基礎工程、離岸風電', '國科會計畫：支撐基腳貫入與提腿對鄰近基樁側向承載力之影響（114學年度）；淘刷對離岸風機樁基礎塔筒疲勞損傷之影響（113學年度）；淘刷對離岸風機樁基礎軸向變形行為之影響（112學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T08056&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '曾韋禎' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉至軒', '助理教授', d.id, '土壤力學、土壤加勁、土壤穩定、數值方法、地質災害', '國科會計畫：以紅土作為永續地質聚合物鋁矽酸鹽來源用於紅土穩定之可行性實驗研究（115學年度）；應用3D列印技術製備新型加勁纖維及其對土體剪力強度影響之初步研究（115學年度）；加勁擋土結構機率性地震需求模型之最佳地動強度量值選定與應用研究（114學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T12061&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉至軒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊晏瑜', '助理教授', d.id, '結構健康監測、系統識別、感測器最佳化配置、吊索分析、結構最佳化、車橋識別、竹構造分析', '國科會計畫：研發減碳混凝土之配比設計、材料性質與結構應用研究（114學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T12217&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊晏瑜' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張庭維', '助理教授', d.id, '風工程、地震工程、結構振動分析與控制、數值分析、電腦輔助結構分析、鋼筋混凝土', '國科會計畫：考慮溫度及頻率敏感的黏彈性阻尼高樓結構之抗風性能評估（114學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T13148&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張庭維' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '紀懿恩', '助理教授', d.id, '結構工程、地震工程、振動台試驗、非結構牆之地震反應、橡膠支承墊', '國科會計畫：鋅心橡膠支承墊的發展與實驗（115學年度）', '', 'https://civil.fcu.edu.tw/teachers-detail/?id=T14173&unit_id=CE01', 'https://civil.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '土木工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '紀懿恩' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '闕帝丰', '副教授', d.id, '創意文學教學、18世紀英國文學、復辟時期戲劇、性別研究、失能研究、年老研究', '國科會計畫：A Dilemma: Social Expectations Versus Personal Values in Regeneration（110學年度）；弱勢群體之自我實現－以《關鍵少數》與《幸福綠皮書》為例（109學年度）；斯莫里特三本主要小說中的醫療世界（108學年度）', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T05227&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '闕帝丰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '董綺安', '副教授', d.id, '自主學習、學習動機、英文寫作、學習策略', '', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T82111&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '董綺安' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周玉楨', '助理教授', d.id, '第二外語學習、語言學習策略、課程規劃、語言測驗', '國科會計畫：外籍學生之華語文、英文語言需求分析與跨文化能力之關聯性--以逢甲大學為例（111學年度）；以自製英語繪本教授「海洋資源與永續議題課程」以提升國小學生英語學習興趣及海洋環保意識（110學年度）；以CLIL教學結合英語和藝術課程——探討國小學童學習態度、英語字彙識讀與口說能力提升之成效（109學年度）', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T91101&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周玉楨' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡明秀', '助理教授', d.id, '中英口譯、中英筆譯、英語教學、商用英文、國際事務英文、口筆譯理論與實務、國際會展英文', '國科會計畫：利用影片式社群註解結合探究式學習模式提升EFL學習者的搭配詞知識（114學年度）；多機器人系統輔助英語課堂教學之實作與其學習成效（112學年度）；設計及開發一個支援個人化學習與教材推薦之英語跟讀學習系統-2（111學年度）', '指導學生競賽／獲獎紀錄（官網列5筆）：大臺中雙語導覽影片競賽最佳語言應用獎指導老師／國立臺中科技大學（2018）；大臺中雙語導覽影片競賽銅牌獎指導老師／國立臺中科技大學（2017）；大臺中雙語導覽影片競賽最佳影片創意獎指導老師／國立臺中科技大學（2017）；2015文藻盃全國大專組英語即席演講比賽指導老師／文藻外語大學（2015）；2014國立中興大學口筆譯大賽指導老師／國立中興大學外文系（2014）', 'https://fll.fcu.edu.tw/teachers-detail/?id=T89097&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡明秀' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉川豪', '助理教授', d.id, '莎士比亞、英國近現代戲劇、亞裔美國文學、飲食與文學、醫療人文', '', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T13038&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉川豪' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪筱婷', '助理教授', d.id, '性別研究、現代歐陸文學、小說理論、語言教學、比較文學', '', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T11163&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪筱婷' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉怡君', '助理教授', d.id, '烏托邦文學、翻譯與改編研究、附文本研究、女性文學', '國科會計畫：重估歐威爾在臺灣的文學聲譽：2014年以降的譯本與來生（113學年度）；比較《小婦人》原著與改編電影《她們》二者對女性主義烏托邦呈現之差異（112學年度）', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T10016&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉怡君' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳萱芳', '助理教授', d.id, '語言學（語音學、心理語言學、語言習得）、翻譯、學術英文寫作、雙語教育、語言評量實務', '', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T13035&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳萱芳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝宏濱', '助理教授', d.id, '翻譯學理論、法律翻譯、法律語言學、比較法學、經濟學', '', '', 'https://fll.fcu.edu.tw/teachers-detail/?id=T09048&unit_id=CH06', 'https://fll.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '外國語文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝宏濱' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '鄭慧如', '教授', d.id, '新詩、現代文學、台灣文學、俗文學、現代詩', '國科會計畫：台灣當代詩的批評想像與創作命題：1980-1999（108學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T84055&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '鄭慧如' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張瑞芬', '教授', d.id, '當代小說、台灣文學、當代散文研究', '', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T83044&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張瑞芬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '余風', '教授兼系主任', d.id, '文字學、訓詁學、漢字地名學、數位人文、影像與平面設計', '國科會計畫：臺中驛記憶地圖再現：鐵道敘事與城市文化之互動與實踐（115學年度）；文學與地景── ──陳千武山林作品及其地理空間之研究（113學年度）；海鮮類飲食文化所見字詞探源及其文化分析（112學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T98023&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '余風' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李寶玲', '副教授', d.id, '詩學、詞學、現代文學', '國科會計畫：故園無此味，何必苦思歸：元和文人的南方飲食書寫與記憶（110學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T79095&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李寶玲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉仲倫', '副教授', d.id, '表演藝術、戲劇教育、專業劇場、文化創意產業', '', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T87079&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉仲倫' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '廖崇斐', '副教授', d.id, '儒學、中國思想史', '國科會計畫：儒家「藝教」思想的現代詮釋與實踐（110學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T01203&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '廖崇斐' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '梁雅英', '副教授', d.id, '明清詞研究、專家詞、現代散文創作、閱讀與書寫', '國科會計畫：離散與南洋：黃勗吾《白雲紅樹館詞鈔》研究（115學年度）；新時代與舊體文學：香港詞人潘小磐《餘庵詞 》研究（113學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T10051&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '梁雅英' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李綉玲', '副教授', d.id, '古文字學、文字學、漢語語言學、華語文教學', '國科會計畫：漢初簡帛用字與《說文》重文對讀研究—兼論許慎之重文編纂（115學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T00187&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李綉玲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林世賢', '助理教授', d.id, '《易》學、中國古代身體論與工夫論、先秦儒學、道家思想', '國科會計畫：體知與感通：《近思錄》、《傳習錄》中的識道方法及其在AI時代的意義（115學年度）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T13147&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林世賢' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '徐培晃', '助理教授', d.id, '現代詩、文學理論', '產學合作計畫：澎湖縣作家資料徵集計畫委託案（2022）；《臺詩好好玩》編輯出版計畫（2020）；大學國文課程 議論文教學暨全校辯論賽（2020）', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T97047&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '徐培晃' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊美美', '講師', d.id, '聲韻學、史記、唐宋古文、老莊研究、佛學研究', '', '', 'https://cl.fcu.edu.tw/teachers-detail/?id=T77124&unit_id=CS04', 'https://cl.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '中國文學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊美美' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '許宜珮', '教授', d.id, '益康與高齡宜居環境設計、生態景觀建築設計與規劃、永續環境與綠建築規劃設計', '產學合作計畫：長照醫療企劃及規劃設計（2026）；114年度五塊社區PK合力造村（2025）；以 iCARE 概念優化長照園區醫療空間計畫（2025）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T13125&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '許宜珮' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張莉欣', '教授', d.id, '景觀規劃設計、景觀生態、高層建築綠化、環境生態規劃與設計、建築與都市綠化、園藝、植物園解說設計、解說計畫', '國科會計畫：宮脇造林法之都市野化森林營造與解說教育手法之研究（115學年度）；臺中中央公園土地使用變遷過程對地表溫度之影響 Influences of Changes of Land Use on Surface Temperature in Taichung Central（110學年度）；共融式遊戲場之各年齡層使用者使用情形與滿意度分析-以台中市鰲峰山公園競合體驗遊戲場為例（108學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T98049&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張莉欣' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT 'Lorena Alessio', '教授', d.id, '建築及都市設計、室內設計', '產學合作計畫：義起創未來：文化x創意x永續（2025）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T12078&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = 'Lorena Alessio' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林葳', '教授', d.id, '建築與室內設計、室內與建築聲學設計、永續與建築環境控制系統、跨域創意整合', '國科會計畫：聲學超材料之應用對於小型房間聲場優化研究（115學年度）；使用縮尺模型量測探討室內樂聲能擴散性之最佳化設計（114學年度）；鹿港歷史步行街區多重聲景之自明性研究（114學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T07031&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林葳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李英弘', '教授', d.id, '視覺資源經營管理、遊憩資源經營管理、觀光遊憩區規劃', '產學合作計畫：以 iCARE 概念優化長照園區醫療空間計畫（2025）；漢玥辦公室環境診斷諮詢顧問專案計畫（2025）；豐河岸住宅室內環境診斷諮詢顧問專案計畫（2024）', '指導學生競賽／獲獎紀錄（官網列2筆）：最佳論文指導獎／中華民國戶外遊憩學會（2010）；最佳論文指導獎／中華民國戶外遊憩學會（2006）', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T86055&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李英弘' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黎淑婷', '教授兼院長', d.id, '建築設計與室內設計色彩計劃、建築環境整合、建築規劃與設計、節氣建築、建築環境設計色彩計劃', '產學合作計畫：長照醫療企劃及規劃設計（2026）；人工智慧與生物多樣性合作計畫(Artificial Intelligence and Biodiversity Collaboration Project)（2025）；德富莊園-包棟民宿平台專案計畫（2025）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T82022&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黎淑婷' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林佳慧', '教授', d.id, '建築設計、室內設計、室內設計施工管理、室內設計估價、室內空氣品質、室內健康建材、綠建築設計、無障礙設計、高齡日照長照設計、社區營造、地方創生', '產學合作計畫：在宅安老-改善老宅之環境品質策略分析（2025）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T99032&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林佳慧' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李元榮', '教授', d.id, '建築設計、室內設計、數位構築、互動設計', '產學合作計畫：全建築生成系統計畫（2024）；雅豐真鑽六期專案計畫（2024）；生成式室內風格設計智慧系統計畫（2023）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T11055&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李元榮' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '宋玉真', '副教授', d.id, '建築設計、都市設計、建築理論、現代與當代建築史、設計方法', '產學合作計畫：XR技術於建築歷史實虛場域實作應用（2021）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T95081&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '宋玉真' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '盛郁庭', '副教授', d.id, '運算設計、機器人構築、數位製造', '國科會計畫：機器學習輔助自主噴漆機器人（115學年度）；回收材料3D列印自由曲面模板與灌注方法的開發（114學年度）；科研創業計畫：營建自動化-現場施工機器人之泥作工項（110學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T06217&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '盛郁庭' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林幸長', '副教授', d.id, '建築與室內設計、跨領域整合設計、參與式規劃設計、公共藝術創作、社區營造培力', '國科會計畫：地域性農業設施作為微型公共性空間構築之探討-以彰化縣溪湖鎮媽厝國小社區共讀站規劃為例（111學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T94046&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林幸長' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '顏貽祥', '副教授', d.id, '圖像處理、機器人室內空間定位導航系統、深度學習、智慧視覺運算、影像物件偵測及辨識系統、DNA計算、離散數學', '國科會計畫：基於物理感知去霧系統之建築場域塗裝機器人定位技術研究（115學年度）；基於AIoT與空間感知技術之農田土壤濕度即時監測與智慧灌溉預測系統（114學年度）；建築環境整合式自動化機器人之牆面檢測系統（114學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T09025&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '顏貽祥' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林衍良', '副教授', d.id, '建築物理環境、風環境、熱環境研究、建築能效分析、建築生命週期評估、計算流體力學(CFD)應用研究、微氣候模擬分析、綠建築及都市設計', '國科會計畫：建築的色彩影響建築設計課學習氛圍之調查-建築系設計課學習場域之初探（114學年度）；動態照明計畫對半開放式地下樓層之光環境影響-以逢甲大學某校園建築為例（112學年度）；公寓大廈住宅自然通風對室內懸浮微粒減緩之研究–以居家燒香拜拜為例（110學年度）', '指導學生競賽／獲獎紀錄（官網列2筆）：設計競賽傑出指導獎／台灣歐特克（2016）；2014 Autodesk軟體創意設計競賽-最佳指導獎／Autodesk（2014）', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T00048&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林衍良' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蕭俊碩', '副教授', d.id, '永續建築設計暨理論、數位建築設計理論、參數化設計暨實務應用、綠色機能形態學、虛擬實境與互動式設計、都市更新理論與實務、室內設計實務、無障礙環境設計', '國科會計畫：Arduino模組於曲面擬合模板上的應用設計（108學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T95140&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蕭俊碩' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳保寬', '副教授兼學程主任', d.id, 'AI演算技術、機器學習、資料探勘於建築設計規劃應用、智慧城鄉空間資訊分析應用、AR/VR技術於建築設計規劃應用、公眾參與式城鄉空間更新活化執行策略、建築設計與城鄉規劃', '產學合作計畫：以BIM為核心之XR-AIGC整合展示系統於碳中和建築價值溝通模式之應用（2025）；MR與生成式AI技術於建築專業整合加值應用（2024）；區域運輸發展研究中心服務升級2.0 計畫(112-113年)-中區區域-基礎型（2024）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T95059&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳保寬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝銘峯', '副教授', d.id, '都市設計、建築設計、跨領域設計、創造性思考、設計思考、跨域創新、社區營造、聚落保存與再發展、地方創生、眷村活化', '國科會計畫：疫後都市公共空間行為模式與環境設計策略的探討與研究（110學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T07032&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝銘峯' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '趙又嬋', '副教授', d.id, '綠建築、建築生命週期評估、建築光環境、建築碳足跡評估、建築物理環境', '國科會計畫：集合住宅設計特性與蘊含碳排關連性之研究（115學年度）；雙層立面皮層於高層集合住宅室內採光優化之研究 —以沖孔鋁板立面為例（115學年度）；宜居理念下的高層住宅綠化與居住空間特性之研究（114學年度）', '指導學生競賽／獲獎紀錄（官網列2筆）：優良碩士論文指導獎／臺灣建築學會（2022）；優秀論文指導獎／社團法人台灣建築醫學學會（2021）', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T95022&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '趙又嬋' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '曾韋翔', '助理教授', d.id, '在場構築、建築設計、都市調研—非譜系建構物、建築理論', '產學合作計畫：115年度臺中市環境景觀總顧問計畫委託專業服務案(含後續擴充)（2026）；2026礦山藝術季前期踏查研究（2026）；Spolia的當代構築演繹與永續實踐（2024）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T07103&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '曾韋翔' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '高敬賢', '助理教授', d.id, '建築設計、都市設計規劃', '產學合作計畫：貓頭鷹計劃（2025）；義起創未來：文化x創意x永續（2025）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T01244&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '高敬賢' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT 'Nicolas Marechal', '助理教授', d.id, '互動設計、VR 虛擬實境', '國科會計畫：虛擬實境技術於建築實務中的參與式潛力探討：以永續未來生活場景為核心（115學年度）；走向智慧建築的多元科技方法：超越功能和自動化，走向建築、用戶和環境之間的新關係（112學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T08221&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = 'Nicolas Marechal' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張芸翠', '助理教授', d.id, '建築循環經濟與低碳設計策略、建築資訊模型 (BIM) 與地理資訊系統 (GIS) 整合應用、數位孿生技術於建成環境之應用、智慧校園與城市永續治理', '國科會計畫：從異質報修紀錄到設計端資訊需求：社會住宅循環低碳維護之跨場域知識圖譜（115學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T14125&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張芸翠' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '呂耀中', '助理教授', d.id, '永續發展與社區設計、參與式設計與藝術創作、地方創生、社區總體營造', '產學合作計畫：2026社造創生聯合論壇推動計畫—『公民社會・韌性台灣』（2026）；大村鄉公所115年大專生洄游農村計畫-青年留鄉行動與農村共創（2026）；114年臺中市環境景觀總顧問計畫委託專業服務案(後續擴充)（2025）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T10281&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '呂耀中' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '宋非凡', '助理教授', d.id, '數位製造、機器人構築', '產學合作計畫：參數式設計導入展場規劃諮詢顧問專案計畫（2026）；以BIM為核心之XR-AIGC整合展示系統於碳中和建築價值溝通模式之應用（2025）；低碳建築趨勢與智慧營建（2024）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T08237&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '宋非凡' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周郁森', '助理教授', d.id, '西洋建築史、建築技術史研究、文化資產保護、空間敘事、台灣建築史', '國科會計畫：舊建築再利用的新路徑：南郭郡守宿舍『先活化、後修復』的自下而上模式研究（114學年度）；從靜態報告到沉浸體驗：VR 技術在傳統廟宇修復紀錄與推廣之應用，以南瑤宮古蹟修復為例（114學年度）；老舊偏鄉社區再造的當代創新作法探討：以「海口放送」計畫為例（112學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T08043&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=3', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周郁森' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉柏昇', '助理教授', d.id, '計算設計與數位營造、再利用建材、體驗式與改革性學習法 (基礎設計教育學)、都市數據分析與證據型設計、生物材料工程設計與建築應用、類淤泥建材工程設計與建築應用、建築結構細部與有限元素法應力分析', '國科會計畫：石門水庫淤泥經750℃秒煅燒後複配矽酸鋁取代偏高嶺土於LC3製程（115學年度）；國際淨零技術生態創新聯盟（114學年度）；高比例改質生物炭於無機聚合物漿體中作為試劑之機械性能研究（114學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T09193&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=3', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉柏昇' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '凃昭伃', '助理教授', d.id, '建築結構、非結構物耐震、建築設計', '國科會計畫：基於水蜘蛛仿生機制之「單元化殼膜一體」全承重結構體系研究（115學年度）；從真菌到建築：菌絲體複合材料於永續建築之應用與發展研究（114學年度）；台灣傳統寺廟震害逃生策略之研究－以台中傳統寺廟為例（113學年度）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T11041&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=3', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '凃昭伃' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '梁君輝', '講師', d.id, '深度學習(機器學習，強化學習，電腦視覺)、數位影像處理(AOI, image preprocessing)、程式設計(python,C,C++)、單板電腦程式開發(Nvidia jetson, Raspberry Pi, MCU)', '產學合作計畫：三維水泥公共藝術案-2（2026）；台中捷運微型圖書館公益計畫（2025）；三維水泥公共藝術案－1（2021）', '', 'https://archschool.fcu.edu.tw/teachers-detail/?id=T13040&unit_id=AS00', 'https://archschool.fcu.edu.tw/faculty/?post_page=3', '2026-11-11'
FROM departments d WHERE d.name = '建築學士學位學程' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '梁君輝' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '江向才', '教授', d.id, '審計學、企業永續、財務報表分析、國際財務管理', '產學合作計畫：規劃及推動2026企業永續管理師計畫第一期（2026）；規劃及推動2025企業永續管理師計畫第一期（2025）；規劃及推動2024企業永續管理師計畫第三期（2024）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T89102&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '江向才' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '張森河', '教授', d.id, '財務會計、管理會計、財務管理、財務報表分析、中國式管理、環境會計', '', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T92104&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '張森河' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '翁慈青', '教授', d.id, '財務會計、審計學、內部控制、公司治理', '國科會計畫：企業社群網絡平台的經營對會計盈餘資訊內涵之影響（112學年度）；政府補助是否影響企業的盈餘資訊內涵?以中國為例（111學年度）；個人會計師參與會計師公會對其審計品質的影響（108學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T99064&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '翁慈青' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '盧鈺欣', '教授', d.id, '財務會計、會計資訊系統、電腦審計、資料探勘', '產學合作計畫：營建工程成本預測模型合作案（2022）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T00112&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '盧鈺欣' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳光政', '教授', d.id, '財務會計、會計資訊系統', '國科會計畫：空污與管理人員利益擷取（115學年度）；地理接近性、文化相似性與薪酬-績效敏感性（114學年度）；地理接近性與合夥會計師性別（113學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T00111&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳光政' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林嬌能', '副教授', d.id, '財務會計、稅務會計', '', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T97064&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林嬌能' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃娟娟', '副教授', d.id, '會計資訊系統、成本會計、財務會計', '', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T81146&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃娟娟' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '施念恕', '副教授', d.id, '財務會計、審計學、成本與管理會計', '國科會計畫：內部碳定價及其影響：從臺灣的法規轉型中汲取洞見（114學年度）；強制碳排放揭露對企業排放量與公司價值之影響：以臺灣上市公司為例（114學年度）；強制揭露、自願揭露和碳風險（113學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T97065&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '施念恕' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '高惠松', '副教授', d.id, '財務會計、公司治理、人工智慧', '國科會計畫：永續準則有資訊價值嗎？ IFRS S1/S2 與資訊內涵（115學年度）；永續平衡計分卡之規劃與設計：台茶文化淨零永續之應用（114學年度）；虛擬通貨會計處理之價值攸關性—以採用NFT之企業為例（111學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T97069&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '高惠松' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '曹秀惠', '副教授', d.id, '智慧資本、會計資訊系統、電腦稽核、企業資源規劃', '', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T00226&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '曹秀惠' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳東憲', '副教授兼系主任', d.id, '電腦稽核、會計資訊系統、內部稽核', '國科會計畫：內部稽核特性、董事會特性與資訊科技治理成效（108學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T02174&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳東憲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王文聖', '副教授', d.id, '公司治理、公司理財、企業社會責任', '國科會計畫：Covid-19前後，從事ESG對於企業融資決策的影響 -以台灣上市公司為例（112學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T09067&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王文聖' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林書賢', '副教授', d.id, '財務會計、審計、公司治理、環境、社會與治理', '國科會計畫：永續背景發言人與資訊吸收：兼論投資人關係的角色（115學年度）；建置台灣上市櫃企業之永續商業資訊：永續漂綠指標與氣候空話指標（115學年度）；亡羊補牢：董事真的懂企業數位責任嗎?論董事會多樣性之重要性（115學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T11216&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林書賢' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳周燕', '助理教授', d.id, '聯合貸款、公司治理、REITs、永續環境', '', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T10057&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳周燕' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳品如', '助理教授', d.id, '審計品質、審計公費、審計委員會、內部控制', '國科會計畫：會計人才短缺如何影響財務報表可比性？探討人工智慧投資與審計公費之角色（115學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T11054&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳品如' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李慧慈', '助理教授', d.id, '會計學、稅務規劃、審計學、企業理財、行為財務學', '', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T12059&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李慧慈' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '伍大開', '助理教授', d.id, '租稅法、財政學、應用個體計量', '國科會計畫：政治意識形態與稅收預測誤差：以美國州政府為例（115學年度）；股利稅、投資與經濟成長：以1998年兩稅合一為例（114學年度）；臺灣稅收彈性之估計（114學年度）', '', 'https://acct.fcu.edu.tw/teachers-detail/?id=T12060&unit_id=CB01', 'https://acct.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '會計學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '伍大開' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊明晶', '特聘教授', d.id, '公司財務、國際財務管理、國際投資學、衍生性金融商品、風險管理', '國科會計畫：綠色保險市場的均衡與政府的角色（114學年度）；美國川普總統就職演說對台灣不同產業各類股的警訊（114學年度）；在普惠金融之下我國銀行金融科技數位化對其財務績效的影響（112學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T84012&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊明晶' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳仰哲', '教授', d.id, '金融機構財務風險管理、深度學習在金融領域的應用、金融機構永續競爭力(ESG)', '國科會計畫：綠色保險市場的均衡與政府的角色（114學年度）；基於流行病模型的精算應用與風險管理（112學年度）；考量抗災、金融創新與政府介入下的巨災保險市場均衡（109學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T00229&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳仰哲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳清和', '教授', d.id, '市場微結構、投資學、期貨與選擇權', '國科會計畫：投資人意見分歧與選擇權市場的錯誤反應（115學年度）；意見分歧對於選擇權市場波動度的影響（115學年度）；交易者意見的分歧對指數選擇權市場的影響（114學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T04060&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳清和' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李君屏', '教授', d.id, '金融機構管理、衍生性金融商品、風險管理', '國科會計畫：死亡率跳躍、違約風險與長壽交換契約之評價（110學年度）；道德風險、市場監督力量與資本市場基礎保險權益保證之評價（109學年度）；系統風險、資本規範與保險安定基金成本（108學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T91041&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李君屏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '洪偉峰', '教授', d.id, '量化交易、機構投資人交易行為、公司理財', '國科會計畫：路徑相依的賭博偏好：投資人為何只對部分極端股票進行賭博（115學年度）；極端報酬率和市場狀態的關係（114學年度）；殘差極端報酬與因子配置極端報酬重要嗎?（113學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T97109&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '洪偉峰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王佳真', '副教授', d.id, '投資管理、國際財務管理', '', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T94050&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王佳真' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉炳麟', '副教授', d.id, '財務計量、風險管理、投資組合分析', '國科會計畫：機器人理財之投資風險屬性評估（109學年度）；買賣方力道對於財務波動性外溢效果的影響（108學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T98074&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉炳麟' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡函芳', '副教授', d.id, '公司理財、公司治理、財務會計', '國科會計畫：線性或非線性？企業長短期投資決策影響因素之探討（114學年度）；伊斯蘭教義是否可以取代公司治理機制？─以印尼上市公司為例（112學年度）；伊斯蘭教義與公司治理機制的替代效果（111學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T09201&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡函芳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '李宗儒', '副教授', d.id, '金融科技、綠色金融、智慧交易、機器學習與數據分析', '國科會計畫：運用大型語言模型建構臺灣市場情緒指標： 多元資訊來源之整合研究（114學年度）；基於深度學習的高頻交易買賣力量預測及其策略應用研究（113學年度）；基於情緒指標與聲量指標的交易策略實證研究-以台灣50為例（112學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T08197&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '李宗儒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉峰旗', '副教授', d.id, '財務計量方法、貝氏分析、統計計算、商業分析', '國科會計畫：有序時間序列模型於股價報酬率區間預測之應用（115學年度）；長照車隊數位大聯盟-無障礙交通接送公自費預約媒合平台研發與推廣（114學年度）；具零壹膨脹的設限計數型時間序列之貝氏建模（112學年度）', '指導學生競賽／獲獎紀錄（官網列4筆）：指導統計學應用競賽 金獎／逢甲大學商學院/金融學院（2019）；指導統計學應用競賽 佳作／逢甲大學商學院/金融學院（2018）；指導統計學應用競賽 銅獎／逢甲大學商學院/金融學院（2018）；指導統計學應用競賽 銀獎／逢甲大學商學院/金融學院（2018）', 'https://fina.fcu.edu.tw/teachers-detail/?id=T97010&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉峰旗' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳宗佑', '副教授', d.id, '投資學、資產定價、行為財務學', '國科會計畫：凸顯性、定錨與市場異常現象（115學年度）；台灣股票市場獲利能力溢酬之探討：風險補償或錯誤定價?（115學年度）；錯誤定價、套利風險與橫斷面股票報酬（114學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T09222&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳宗佑' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳麗君', '副教授兼系主任', d.id, '財務工程、資產定價、能源財務', '國科會計畫：投資者情緒、關注度與交易行為：考量公司特徵、市場狀態與投資人異質性之研究（115學年度）；產業特性對市場情緒傳導效應之調節作用：基於大型語言模型的實證研究（114學年度）；台灣企業碳排放治理與綠色創新對財務績效的綜效分析（113學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T01066&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳麗君' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '莊明哲', '副教授', d.id, '財務工程、衍生性金融商品、利率模型、氣候衍生性商品', '國科會計畫：浮動利率公債之系統性超額利差：動態無套利利率期限結構模型下之風險補償與定價分析（115學年度）；黃金掛鉤加密貨幣（PAXG、XAUT）與國際黃金市場價格連動性之實證分析（115學年度）；修正無套利期限結構與債券評價模式：狀態空間模型之應用（114學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T06218&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '莊明哲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝依婷', '副教授', d.id, '聯合貸款、財務會計、合併收購', '國科會計畫：動搖銀行貸款定價的外部因素：擔保品途徑（115學年度）；財務報表重編嚴重度及其市場與債權市場之經濟後果 / The Severity of Financial Restatements and Their Consequences for Equity and Debt Markets（115學年度）；綠色抉擇：特殊關係對綠色融資決策與執行的影響（114學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T06219&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝依婷' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '謝金育', '助理教授', d.id, 'Social Computing: Influence evaluation、Social Finance: Crowdfunding、Social Investing、Deep learning', '國科會計畫：電競經濟服務媒合機制設計（114學年度）；運用社群智慧與深度學習之時尚搭配推薦機制（111學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T10294&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '謝金育' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '武氏紅芳', '助理教授', d.id, '家族企業傳承、財富管理、供應鏈永續管理', '國科會計畫：家庭資產組合選擇的動態分析 : COVID-19疫情及金融危機後歐洲實物資產持有的實證研究（114學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T11213&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '武氏紅芳' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃迦怡', '助理教授', d.id, '金融市場微結構、企業資訊揭露與市場反應、金融數據分析、永續金融', '', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T15009&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃迦怡' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '廖文如', '助理教授', d.id, '統計軟件應用(Python、 SAS、 Eviews、 Stata)、公司治理、行為財務、盈餘管理', '', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T13141&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '廖文如' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉孟宜', '助理教授', d.id, '財務管理、共同基金、公司理財、風險管理', '', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T99169&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉孟宜' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林家仰', '助理教授', d.id, '代理人基(agent-based)計算經濟、行為與實驗經濟、經濟成長、時間序列與市場分析', '國科會計畫：普惠金融在台灣碳排放中的角色（112學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T12171&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林家仰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳珮瀅', '助理教授', d.id, '公司財務、公司治理、財務會計', '國科會計畫：CEO權力與資本結構調整速度的探討（111學年度）', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T10055&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳珮瀅' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王鈺仁', '助理教授', d.id, '財務計量(Quantitative finance)、金融數據視覺化(Finance data visualization)、財務風險管理(Financial risk management)、財務數值方法(Numerical methods in finance)、衍生性金融商品(Derivatives)、巨量資料分析 (Big data analysis)、智能系統設計(Intelligent system design)、5G網路應用(5G network application)', '', '', 'https://fina.fcu.edu.tw/teachers-detail/?id=T11120&unit_id=CB03', 'https://fina.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '財務金融學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王鈺仁' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '曾鼎翔', '特聘教授', d.id, '國際行銷、服務行銷、關係行銷', '國科會計畫：同理心–信任校準悖論：設計具透明性的聊天機器人以促進更佳服務決策（115學年度）；當腔調遇上仇視：生成式人工智能語音模式的國家聯想與使用行為（114學年度）；探討功能性因子與擬人化社會性因子對持續使用生成式人工智慧搜尋引擎之意圖的影響（113學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T97241&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '曾鼎翔' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '楊明憲', '教授', d.id, '國際農產貿易、農業經濟、農業政策分析、WTO與兩岸經貿', '', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T82102&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '楊明憲' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '江怡蒨', '教授', d.id, '國際財務金融', '國科會計畫：台商海外投資與融資策略-兼論新冠疫情影響（111學年度）；台商海外投資，新冠疫情與財務彈性（110學年度）；現金持有管理是否能提升公司價值? 兼論海外投資與不對稱效果（109學年度）', '指導學生競賽／獲獎紀錄（官網列5筆）：111年補助學生赴新興市場企業實習計畫實習專題競賽卓越指導教師獎／經濟部國際貿易局（2022）；110年補助學生赴新興市場企業實習計畫實習專題競賽卓越指導教師獎／經濟部國際貿易局（2021）；108年補助學生赴新興市場企業實習計畫實習專題競賽卓越指導教師獎／經濟部國際貿易局（2019）；107年補助學生赴新興市場企業實習計畫實習專題競賽卓越指導教師獎／經濟部國際貿易局（2018）；106年補助學生赴新興市場企業實習計畫實習專題競賽卓越指導教師獎／經濟部國際貿易局（2017）', 'https://itra.fcu.edu.tw/teachers-detail/?id=T81093&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '江怡蒨' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '梁馨予', '教授', d.id, '財務管理、公司治理、永續金融、金融機構經營管理', '國科會計畫：建置台灣上市櫃企業之永續商業資訊：永續漂綠指標與氣候空話指標（115學年度）；探討台灣上市企業ESG分數與股利政策之關聯性（112學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T96201&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '梁馨予' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '許鈺珮', '教授', d.id, '國際貿易、產業組織、賽局理論', '國科會計畫：數位化與外人直接投資流入（111學年度）；智慧財產權與臺灣製造業廠商之對外直接投資模式（110學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T96194&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '許鈺珮' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '邱世寬', '教授', d.id, '企業成長與創業精神、組織治理與企業社會責任、國際企業管理', '國科會計畫：時尚產業可能做到永續嗎？（110學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T90146&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '邱世寬' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林呈昱', '教授兼系主任', d.id, '行銷管理、零售管理', '國科會計畫：台灣消費者接受零售商基礎行動支付服務的直接和間接信任轉移機制（114學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T99198&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林呈昱' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳廣文', '副教授', d.id, '消費者行為、網路行銷、國際行銷', '國科會計畫：網紅代言人效應對消費者忠誠度之影響—以網紅類型為干擾變數（112學年度）', '指導學生競賽／獲獎紀錄（官網列5筆）：傑出指導老師獎／昌立聯合開發股份有公司（2016）；傑出團隊指導老師獎／歐都納股份有限公司（2016）；傑出團隊指導教師獎／味丹文教基金會（2015）；傑出團隊指導教師獎／歐都納股份有限公司（2014）；優良團隊指導教師獎／味丹文教基金會（2013）', 'https://itra.fcu.edu.tw/teachers-detail/?id=T95023&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳廣文' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '吳文臨', '副教授', d.id, '國際投資、國際財務管理、國際金融', '國科會計畫：創新的有效性對外匯曝險的影響：以台灣企業為例（113學年度）；分析後疫情時代塑膠製品供應商之評選構面與準則-以台灣中小企業為例（111學年度）；跨國性社會互動對國際投資組合投資的影響（108學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T00071&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '吳文臨' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉翁世昆', '副教授', d.id, '國際貿易實務、網路貿易、供應鏈管理', '國科會計畫：跨國品牌活動之在地化決策：以法國品牌於文化敏感市場之實踐為例（115學年度）；台灣三義木雕推廣至泰國木雕市場之行銷決策成功因素（112學年度）；台灣傳統漆藝工藝前進中東阿拉伯聯合大公國家具市場之行銷策略成功因素（110學年度）', '指導學生競賽／獲獎紀錄（官網列1筆）：榮獲經濟部國貿局「經濟部補助國內公私立大學校院選送學生赴新興市場企業實習計畫」-卓越指導教師獎／經濟部國際貿易局（2022）', 'https://itra.fcu.edu.tw/teachers-detail/?id=T99086&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉翁世昆' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃秀英', '副教授', d.id, '全球在地化、風土產品消費、個案研究、國際貿易實務', '國科會計畫：風土產品消費價值意義模型之建立–以農產品為例（108學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T01064&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃秀英' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '邱安安', '副教授', d.id, '財務會計、財務管理、會計資訊系統、公司治理、企業永續會計', '國科會計畫：導入SBTN框架對永續報告書可信度與投資意願之影響（115學年度）；利用生成式 AI 識別企業永續報告之氣候漂綠與印象管理行為（115學年度）；探討臺灣企業漂綠及漂棕行為對於公司價值之影響（113學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T95111&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '邱安安' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '董正玫', '副教授', d.id, '產業分析、創新創業、創新管理、行銷管理', '國科會計畫：以科技接受模式探討網路直播—虛擬主播對消費者購買意願之影響（113學年度）；B型企業的行銷策略-以綠藤生機為例（109學年度）；企業在B2B跨境電商平台所面臨挑戰之探討 ― 以美妝保養產業為例（108學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T04254&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '董正玫' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '葉敬軒', '副教授', d.id, '消費者/使用者心理與行為、網路行銷、顧客關係管理、零售管理與科技、國際行銷', '國科會計畫：社群媒體對正式與非正式學習影響的縱貫性分析：自我差異理論觀點（115學年度）；虛擬網紅如何建立心理認同？整合擬人化、使用滿足與社會認同理論之觀點（115學年度）；社群媒體與學習效果間關係的再檢視：非正式學習觀點（114學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T08183&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '葉敬軒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉世慶', '副教授', d.id, '企業倫理、跨文化管理、企業社會責任、策略管理、企業永續管理', '國科會計畫：天人合一(E)、里仁為美(S)、先義後利(G)—華人儒家倫理對台灣企業永續影響之探討（115學年度）；ESG趨勢下，對於企業社會公益的哲學基礎、策略管理、影響力評估的探究（113學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T12065&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉世慶' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '江成欣', '助理教授', d.id, '電子商務、線上社群、跨境電商、社會網路分析、專利分析', '國科會計畫：地緣政治衝擊下先進封裝技術之研發韌性：技術路徑分叉與網絡碎片化分析（115學年度）；從遊戲化應用於金融科技分析消費者對投資看法及影響研究（113學年度）；跨境電商品牌形象與知覺價值對消費者購買意願之影響以GMARKET為例（111學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T08179&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '江成欣' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林冠文', '助理教授', d.id, '會展行銷、會展管理、數位會展科技應用管理、文化經濟與貿易', '', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T12058&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林冠文' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳倩儀', '助理教授', d.id, '國際貿易、金融科技與供應鏈金融、永續與綠色金融、智慧醫療、創新創業', '', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T14161&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳倩儀' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '商瓈丹', '助理教授', d.id, '應用經濟、大數據分析、數據科學', '產學合作計畫：115年度「新住民支持政策資源配置之研究：以『新住民基本法』第六條為分析基礎（2026）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T12190&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '商瓈丹' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林介勝', '助理教授', d.id, '國際企業、策略管理、企業社會責任、組織韌性', '國科會計畫：企業社會責任能否減少危機損害？—基於財務與非財務績效的雙重觀點（115學年度）；股權集中度與企業社會責任專一化之關聯性探討（115學年度）；國家ESG表現對創業之影響：制度觀點（114學年度）', '', 'https://itra.fcu.edu.tw/teachers-detail/?id=T13089&unit_id=CB02', 'https://itra.fcu.edu.tw/teachers/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '國際經營與貿易學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林介勝' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '蔡忠杓', '講座教授', d.id, 'CAD/CAM、機械設計、機構學、齒輪設計與分析', '', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T00130&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '蔡忠杓' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '周至宏', '講座教授', d.id, '人工智慧、資訊技術與系統整合、穩健優化技術、系統動力與控制、自動化系統整合技術', '國科會計畫：群體尋優演算法的效能改善研究及其在工程問題之優化設計的應用（112學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T04213&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '周至宏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '黃錦煌', '講座教授', d.id, '微感測器與微致動器、智慧型材料、微機電系統、電聲系統設計、電腦輔助分析', '國科會計畫：智慧聲場分析與 AI 優化建議系統研發（114學年度）；電容式與壓電式微機電麥克風之設計、分析模型建立、製作、量測及驗證（114學年度）；壓電式微機電揚聲器振膜優化與聲學性能提升研究（114學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T81055&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '黃錦煌' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王啟昌', '特聘教授', d.id, '熱設計與熱決策、工具機熱設計、快熱與熱變位補償技術、感測器設計與智慧決策', '國科會計畫：虛實整合技術提升先進封裝設備之熱品質、節能與預知保養技術開發─以志聖半導體設備為例（114學年度）；無外加溫度感測與現場修模之工具機空間熱變位補償探討（114學年度）；無外加溫度感測與現場修模之5軸工具機空間熱變位補償探討（112學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T98389&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王啟昌' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '羅致卿', '教授', d.id, '電腦數值控制、電腦輔助製造、系統動態建模與分析、數控工具機', '', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T81100&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '羅致卿' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '劉顯光', '教授', d.id, '高分子複合材料、陶瓷複合材料、微機電系統、薄膜材料', '國科會計畫：積層製造氧化石墨烯複合盤應用於氟化鈣晶圓超平滑及無損傷之化學機械拋光（115學年度）；超高頻三次元還原氧化石墨烯吸波複合材料之製程與吸波效能分析（114學年度）；複合式氧化石墨烯/瀝青研光盤應用於氟化鈣晶圓化學機械研磨之延性製造研究（113學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T81190&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '劉顯光' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林孟儒', '教授', d.id, '微機電力學、微光機電系統', '國科會計畫：熱成像輔助靜止障礙物辨識於智慧載具安全應用之研究（115學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T91042&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林孟儒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '彭信舒', '教授', d.id, '塑膠產品設計、射出成型、模具設計、CAE分析、工廠現場診斷與輔導', '國科會計畫：雙品質可預測技術應用於多模穴回收料發泡射出產品模具開發與製程技術之研究（115學年度）；射出機系統即時資訊結合智能化關鍵技術應用於回收料/生質材料射出產品成型特性研究計畫（115學年度）；創新氣輔式熱源機制結合可視化智能關鍵技術建置與應用於永續性中空輕量化產品成型特性研究計畫(2/3)（113學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T04059&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '彭信舒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '王坤卿', '教授', d.id, '信號處理、人工智慧、電腦視覺、物聯網應用', '國科會計畫：高噪聲工業聲學健康監測之無監督異常偵測：以 WGAN-GP 為核心之生成式學習方法（115學年度）；基於時頻關注機制的聲學分析與卷積神經網路的應用:以智慧化腸道疾病診斷與照護系統開發為例（114學年度）；超高速流體動力主軸及智能化監控裝置開發計畫（113學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T09051&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '王坤卿' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '袁長安', '教授兼系主任', d.id, '固體力學與有限單元法、半導體封裝技術與可靠度、AI替身模型與工程應用、製造排程實務', '國科會計畫：AI驅動階層式非線性等效結構於2.5D/3D集成封裝三維全尺寸模擬之研究（115學年度）；基於遷移式學習與逆運算之FCI排程動態參數最佳化決策機制（115學年度）；應用柔性限制條件技術之動態多目標預測-反應式智慧製造排程實務研究（114學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T06045&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '袁長安' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳秋宏', '副教授', d.id, '人工智慧、生成式AI設計、工業機器人、智慧製造、演化計算', '國科會計畫：虛實整合系統中工業機器人實體與虛擬模型定位偏差快速校正之研究-基於生成式AI及深度感測器之低成本解決方案（115學年度）；整合深度學習視覺辨識與數據手套示教之機械手臂控制系統（115學年度）；建立生成式AI與演化計算合作求解流程於工業機器人與連桿機構逆運動學多重解之研究（114學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T07050&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳秋宏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '郭武彰', '副教授', d.id, '五軸CNC銑削加工程式編排與實務操作、三軸與四軸CNC銑削加工程式編排與實務操作、CNC車床加工程式編排與實務操作', '產學合作計畫：銅製水五金廠管理應用加值計畫（2026）；主軸預熱與控溫技術開發（2024）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T10259&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '郭武彰' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '詹彥信', '副教授', d.id, '高/低溫燃料電池系統整合設計與效能評估、系統熱質能分析、高溫熱流體質傳現象探討、微尺度材料結構與質傳現象分析', '國科會計畫：結合數值分析與實驗驗證被動式捕塵淨化模組流場優化研究（115學年度）；氫載體對於再生能源與固態氧化物電池之發電/共電解性能和效率影響（115學年度）；以數值結合實驗方式評估單元電池物理特性對於再生能源結合SOFC/SOEC系統效率影響（115學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T10291&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '詹彥信' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '陳子夏', '助理教授', d.id, '機械設計、傳動系統、機電整合', '國科會計畫：精密放電加工添加界面活性劑後之放電液加工特性研究之研究（109學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T05249&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '陳子夏' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '魏立儒', '助理教授', d.id, '積層製造、直寫技術、印刷電路、傳感技術、創新設計', '國科會計畫：重型長軸CNC車床床身結構剛性之數值分析（115學年度）；整合熱成像、人臉識別與路徑規劃的無人機技術研究（113學年度）；開發光固化積層製造技術用於具感測功能之智慧材料（110學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T07206&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '魏立儒' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林玉堃', '助理教授', d.id, '機電整合自動化、訊號處理、機器學習、磨削加工', '國科會計畫：高速流體驅動主軸之智慧監測與健康預診技術研究（115學年度）；基於熱成像與可見光之影像融合於物件辨識之夜間校園巡檢系統研究（115學年度）；智慧型超音波振動系統即時回控技術（114學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T12193&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林玉堃' AND x.department_id = d.id);
INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)
SELECT '林明賢', '助理教授', d.id, '固體力學數值分析、微機電系統、精密量測', '國科會計畫：結合數值分析與實驗驗證被動式捕塵淨化模組流場優化研究（115學年度）；基於數值模擬方法於電解電池之性能探討與熱應力研究（115學年度）；校園不平整路面偵測應用於自走車提前避障技術（115學年度）', '', 'https://mcae.fcu.edu.tw/teachers-detail/?id=T12291&unit_id=CE04', 'https://mcae.fcu.edu.tw/faculty/?post_page=2', '2026-11-11'
FROM departments d WHERE d.name = '機械與電腦輔助工程學系' AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = '林明賢' AND x.department_id = d.id);
INSERT INTO teacher_skills (teacher_id, skill_id, confidence, source)
SELECT t.id, s.id, v.c, 'LLM' FROM (VALUES
  ('劉安之', '資訊工程學系', '雲端與網路', 0.88),
  ('劉安之', '資訊工程學系', 'SQL', 0.85),
  ('張真誠', '資訊工程學系', '深度學習', 0.95),
  ('張真誠', '資訊工程學系', '資訊安全', 0.93),
  ('張真誠', '資訊工程學系', '通訊與訊號處理', 0.9),
  ('張真誠', '資訊工程學系', '多媒體與影像', 0.88),
  ('張真誠', '資訊工程學系', 'SQL', 0.85),
  ('桑慧敏', '資訊工程學系', '統計', 0.95),
  ('桑慧敏', '資訊工程學系', '數學與數值方法', 0.75),
  ('桑慧敏', '資訊工程學系', '資料分析', 0.75),
  ('桑慧敏', '資訊工程學系', '能源', 0.7),
  ('竇其仁', '資訊工程學系', '雲端與網路', 0.95),
  ('竇其仁', '資訊工程學系', '嵌入式與物聯網', 0.9),
  ('李榮三', '資訊工程學系', '資訊安全', 0.93),
  ('李榮三', '資訊工程學系', '生成式 AI 應用', 0.9),
  ('李榮三', '資訊工程學系', '雲端與網路', 0.65),
  ('王益文', '資訊工程學系', '嵌入式與物聯網', 0.9),
  ('王益文', '資訊工程學系', '電子電路', 0.9),
  ('王益文', '資訊工程學系', '機器學習', 0.85),
  ('王益文', '資訊工程學系', '深度學習', 0.85),
  ('李金鳳', '資訊工程學系', '機器學習', 0.95),
  ('李金鳳', '資訊工程學系', '資訊安全', 0.93),
  ('李金鳳', '資訊工程學系', '多媒體與影像', 0.88),
  ('李金鳳', '資訊工程學系', 'SQL', 0.85),
  ('李金鳳', '資訊工程學系', '資料分析', 0.8),
  ('李俊宏', '資訊工程學系', '機器學習', 0.88),
  ('李俊宏', '資訊工程學系', '程式設計基礎', 0.8),
  ('李俊宏', '資訊工程學系', '專案管理', 0.7),
  ('李俊宏', '資訊工程學系', '統計', 0.7),
  ('李維斌', '資訊工程學系', '資訊安全', 0.93),
  ('李維斌', '資訊工程學系', '多媒體與影像', 0.6),
  ('周兆龍', '資訊工程學系', '資訊安全', 0.93),
  ('周兆龍', '資訊工程學系', '多媒體與影像', 0.85),
  ('周兆龍', '資訊工程學系', '深度學習', 0.65),
  ('林哲維', '資訊工程學系', '生成式 AI 應用', 0.9),
  ('林哲維', '資訊工程學系', '深度學習', 0.88),
  ('林哲維', '資訊工程學系', '機器學習', 0.85),
  ('林志敏', '資訊工程學系', '作業系統與系統程式', 0.95),
  ('林志敏', '資訊工程學系', '嵌入式與物聯網', 0.9),
  ('林志敏', '資訊工程學系', '機器人與自動控制', 0.9),
  ('林志敏', '資訊工程學系', '程式設計基礎', 0.88),
  ('林志敏', '資訊工程學系', '專案管理', 0.55),
  ('林峰正', '資訊工程學系', '資料分析', 0.95),
  ('林峰正', '資訊工程學系', '雲端與網路', 0.95),
  ('林峰正', '資訊工程學系', '深度學習', 0.95),
  ('林峰正', '資訊工程學系', '資料結構與演算法', 0.9),
  ('林峰正', '資訊工程學系', '機器學習', 0.85),
  ('林明言', '資訊工程學系', '資料分析', 0.95),
  ('林明言', '資訊工程學系', '機器學習', 0.88),
  ('林明言', '資訊工程學系', 'SQL', 0.85),
  ('林佩君', '資訊工程學系', '統計', 0.95),
  ('林佩君', '資訊工程學系', '資料分析', 0.95),
  ('林佩君', '資訊工程學系', '機器學習', 0.88),
  ('林佩君', '資訊工程學系', 'UI/UX 設計', 0.6),
  ('林佩蓉', '資訊工程學系', '多媒體與影像', 0.85),
  ('林佩蓉', '資訊工程學系', '機器學習', 0.85),
  ('林佩蓉', '資訊工程學系', '深度學習', 0.85),
  ('林佩蓉', '資訊工程學系', '雲端與網路', 0.85),
  ('林佩蓉', '資訊工程學系', '通訊與訊號處理', 0.65),
  ('洪振偉', '資訊工程學系', '嵌入式與物聯網', 0.9),
  ('洪振偉', '資訊工程學系', '程式設計基礎', 0.85),
  ('洪振偉', '資訊工程學系', '行動應用開發', 0.85),
  ('洪振偉', '資訊工程學系', '專案管理', 0.7),
  ('洪振偉', '資訊工程學系', '雲端與網路', 0.65),
  ('洪維志', '資訊工程學系', '資訊安全', 0.93),
  ('洪維志', '資訊工程學系', '雲端與網路', 0.88),
  ('洪維志', '資訊工程學系', '通訊與訊號處理', 0.65),
  ('張志宏', '資訊工程學系', '雲端與網路', 0.95),
  ('張志宏', '資訊工程學系', '深度學習', 0.95),
  ('張志宏', '資訊工程學系', '資料分析', 0.95),
  ('張志宏', '資訊工程學系', '程式設計基礎', 0.8),
  ('張志宏', '資訊工程學系', '專案管理', 0.7),
  ('郭士煒', '資訊工程學系', '資訊安全', 0.93),
  ('郭士煒', '資訊工程學系', '生成式 AI 應用', 0.9),
  ('郭士煒', '資訊工程學系', '深度學習', 0.88),
  ('郭士煒', '資訊工程學系', '機器學習', 0.85),
  ('郭崇韋', '資訊工程學系', '資訊安全', 0.93),
  ('郭崇韋', '資訊工程學系', '電子電路', 0.9),
  ('郭崇韋', '資訊工程學系', '嵌入式與物聯網', 0.9),
  ('郭崇韋', '資訊工程學系', '雲端與網路', 0.65),
  ('張哲誠', '資訊工程學系', '機器學習', 0.95),
  ('張哲誠', '資訊工程學系', '深度學習', 0.95),
  ('張哲誠', '資訊工程學系', '機器人與自動控制', 0.93),
  ('張哲誠', '資訊工程學系', '雲端與網路', 0.85),
  ('張哲誠', '資訊工程學系', '航太與系統', 0.75),
  ('陳青文', '資訊工程學系', '嵌入式與物聯網', 0.93),
  ('陳青文', '資訊工程學系', '雲端與網路', 0.85),
  ('陳青文', '資訊工程學系', '作業系統與系統程式', 0.78),
  ('陳青文', '資訊工程學系', '通訊與訊號處理', 0.65),
  ('陳德生', '資訊工程學系', '嵌入式與物聯網', 0.93),
  ('陳德生', '資訊工程學系', '電子電路', 0.9),
  ('陳德生', '資訊工程學系', '雲端與網路', 0.65),
  ('陳錫民', '資訊工程學系', '雲端與網路', 0.88),
  ('陳錫民', '資訊工程學系', '程式設計基礎', 0.83),
  ('陳錫民', '資訊工程學系', '專案管理', 0.7),
  ('陳烈武', '資訊工程學系', '機器學習', 0.95),
  ('陳烈武', '資訊工程學系', '嵌入式與物聯網', 0.93),
  ('陳烈武', '資訊工程學系', '通訊與訊號處理', 0.9),
  ('陳烈武', '資訊工程學系', '雲端與網路', 0.68),
  ('許芳榮', '資訊工程學系', '雲端與網路', 0.95),
  ('許芳榮', '資訊工程學系', '機器學習', 0.85),
  ('許芳榮', '資訊工程學系', '深度學習', 0.65),
  ('許芳榮', '資訊工程學系', '資料分析', 0.6),
  ('許芳榮', '資訊工程學系', '多媒體與影像', 0.6),
  ('黃秀芬', '資訊工程學系', '資料結構與演算法', 0.93),
  ('黃秀芬', '資訊工程學系', '雲端與網路', 0.88),
  ('黃秀芬', '資訊工程學系', '數學與數值方法', 0.65),
  ('黃秀芬', '資訊工程學系', '嵌入式與物聯網', 0.65),
  ('黃秀芬', '資訊工程學系', '通訊與訊號處理', 0.65),
  ('游景盛', '資訊工程學系', '資料分析', 0.63),
  ('葉春秀', '資訊工程學系', '專案管理', 0.95),
  ('葉春秀', '資訊工程學系', '多媒體與影像', 0.85),
  ('葉春秀', '資訊工程學系', '程式設計基礎', 0.85),
  ('葉春秀', '資訊工程學系', '深度學習', 0.85),
  ('葉春秀', '資訊工程學系', '機械設計與製造', 0.65),
  ('劉明機', '資訊工程學系', '資料分析', 0.95),
  ('劉明機', '資訊工程學系', '程式設計基礎', 0.85),
  ('劉明機', '資訊工程學系', '機器學習', 0.65),
  ('劉宗杰', '資訊工程學系', '資料分析', 0.95),
  ('劉宗杰', '資訊工程學系', '資訊安全', 0.9),
  ('劉宗杰', '資訊工程學系', '雲端與網路', 0.88),
  ('劉怡芬', '資訊工程學系', '機器學習', 0.95),
  ('劉怡芬', '資訊工程學系', '深度學習', 0.88),
  ('劉怡芬', '資訊工程學系', '統計', 0.85),
  ('劉怡芬', '資訊工程學系', '數學與數值方法', 0.65),
  ('劉怡芬', '資訊工程學系', '通訊與訊號處理', 0.65),
  ('蔡國裕', '資訊工程學系', '資訊安全', 0.93),
  ('蔡國裕', '資訊工程學系', '嵌入式與物聯網', 0.9),
  ('蔡國裕', '資訊工程學系', '雲端與網路', 0.65),
  ('蔡國裕', '資訊工程學系', '行動應用開發', 0.55),
  ('蔡明翰', '資訊工程學系', '多媒體與影像', 0.88),
  ('蔡明翰', '資訊工程學系', '深度學習', 0.85),
  ('薛念林', '資訊工程學系', '程式設計基礎', 0.88),
  ('薛念林', '資訊工程學系', '專案管理', 0.73),
  ('劉文豐', '電機工程學系', '電子電路', 0.93),
  ('劉文豐', '電機工程學系', '通訊與訊號處理', 0.9),
  ('田春林', '電機工程學系', '材料與化工', 0.88),
  ('田春林', '電機工程學系', '電子電路', 0.58),
  ('洪耀正', '電機工程學系', '統計', 0.7),
  ('洪耀正', '電機工程學系', '數學與數值方法', 0.68),
  ('洪耀正', '電機工程學系', '通訊與訊號處理', 0.65),
  ('何子儀', '電機工程學系', '電子電路', 0.93),
  ('何子儀', '電機工程學系', '嵌入式與物聯網', 0.93),
  ('何子儀', '電機工程學系', '機器人與自動控制', 0.93),
  ('何子儀', '電機工程學系', '能源', 0.63),
  ('梁寶芝', '電機工程學系', '電子電路', 0.73),
  ('黃思倫', '電機工程學系', '能源', 0.93),
  ('陳坤煌', '電機工程學系', '電子電路', 0.73),
  ('李企桓', '電機工程學系', '材料與化工', 0.85),
  ('李企桓', '電機工程學系', '電子電路', 0.58),
  ('謝振中', '電機工程學系', '能源', 0.93),
  ('謝振中', '電機工程學系', '電子電路', 0.93),
  ('謝振中', '電機工程學系', '法律與法規', 0.85),
  ('齊立平', '電機工程學系', '電子電路', 0.73),
  ('齊立平', '電機工程學系', '通訊與訊號處理', 0.68),
  ('王壘', '電機工程學系', '嵌入式與物聯網', 0.9),
  ('王壘', '電機工程學系', '資訊安全', 0.9),
  ('王壘', '電機工程學系', '雲端與網路', 0.85),
  ('王壘', '電機工程學系', '機器學習', 0.85),
  ('王壘', '電機工程學系', '作業系統與系統程式', 0.75),
  ('陳志強', '電機工程學系', '電子電路', 0.93),
  ('陳志強', '電機工程學系', '通訊與訊號處理', 0.93),
  ('陳志強', '電機工程學系', '嵌入式與物聯網', 0.65),
  ('曹嶸', '電機工程學系', '電子電路', 0.93),
  ('曹嶸', '電機工程學系', '通訊與訊號處理', 0.65),
  ('黃定彝', '電機工程學系', '電子電路', 0.93),
  ('黃定彝', '電機工程學系', '通訊與訊號處理', 0.93),
  ('黃定彝', '電機工程學系', '數學與數值方法', 0.85),
  ('洪聖均', '電機工程學系', '電子電路', 0.93),
  ('洪聖均', '電機工程學系', '嵌入式與物聯網', 0.9),
  ('洪聖均', '電機工程學系', '材料與化工', 0.85),
  ('洪聖均', '電機工程學系', '雲端與網路', 0.65),
  ('徐士賢', '電機工程學系', '深度學習', 0.95),
  ('徐士賢', '電機工程學系', '能源', 0.93),
  ('徐士賢', '電機工程學系', '數學與數值方法', 0.85),
  ('徐士賢', '電機工程學系', '機器學習', 0.85),
  ('徐士賢', '電機工程學系', '嵌入式與物聯網', 0.65),
  ('黃俊瑋', '電機工程學系', '能源', 0.93),
  ('黃俊瑋', '電機工程學系', '嵌入式與物聯網', 0.9),
  ('黃俊瑋', '電機工程學系', '電子電路', 0.9),
  ('黃俊瑋', '電機工程學系', '機器人與自動控制', 0.9),
  ('黃俊瑋', '電機工程學系', '機器學習', 0.85),
  ('王志洋', '電機工程學系', '電子電路', 0.93),
  ('王志洋', '電機工程學系', '數學與數值方法', 0.88),
  ('王志洋', '電機工程學系', '材料與化工', 0.6),
  ('王志洋', '電機工程學系', '能源', 0.6),
  ('許士軍', '企業管理學系', '管理與組織', 0.93),
  ('許士軍', '企業管理學系', '行銷企劃', 0.9),
  ('許士軍', '企業管理學系', '研究方法', 0.9),
  ('許士軍', '企業管理學系', '商業企劃', 0.63),
  ('佘日新', '企業管理學系', '管理與組織', 0.93),
  ('佘日新', '企業管理學系', '法律與法規', 0.85),
  ('佘日新', '企業管理學系', '國際商務', 0.85),
  ('佘日新', '企業管理學系', '行銷企劃', 0.6),
  ('佘日新', '企業管理學系', '商業企劃', 0.6),
  ('張秀樺', '企業管理學系', '行銷企劃', 0.93),
  ('張秀樺', '企業管理學系', '商業企劃', 0.85),
  ('張秀樺', '企業管理學系', '研究方法', 0.6),
  ('張秀樺', '企業管理學系', '問卷設計', 0.55),
  ('顏上詠', '企業管理學系', '法律與法規', 0.93),
  ('顏上詠', '企業管理學系', '經濟分析', 0.65),
  ('黃誠甫', '企業管理學系', '統計', 0.75),
  ('黃誠甫', '企業管理學系', '數學與數值方法', 0.7),
  ('黃誠甫', '企業管理學系', '資料分析', 0.55),
  ('黃禮林', '企業管理學系', '管理與組織', 0.88),
  ('黃禮林', '企業管理學系', '國際商務', 0.6),
  ('楊曉琳', '企業管理學系', '財務分析', 0.88),
  ('楊曉琳', '企業管理學系', '會計與財務', 0.78),
  ('張寶蓉', '企業管理學系', '管理與組織', 0.93),
  ('張寶蓉', '企業管理學系', '國際商務', 0.85),
  ('張寶蓉', '企業管理學系', '商業企劃', 0.85),
  ('張寶蓉', '企業管理學系', '經濟分析', 0.85),
  ('王智弘', '企業管理學系', '行銷企劃', 0.93),
  ('吳如娟', '企業管理學系', '管理與組織', 0.85),
  ('吳如娟', '企業管理學系', '雲端與網路', 0.8),
  ('吳如娟', '企業管理學系', '資料分析', 0.8),
  ('吳如娟', '企業管理學系', '商業企劃', 0.6),
  ('仇介民', '企業管理學系', '專案管理', 0.95),
  ('仇介民', '企業管理學系', '行銷企劃', 0.9),
  ('仇介民', '企業管理學系', '管理與組織', 0.88),
  ('仇介民', '企業管理學系', '商業企劃', 0.6),
  ('鄭孟育', '企業管理學系', '管理與組織', 0.93),
  ('鄭孟育', '企業管理學系', '研究方法', 0.93),
  ('武垂玲', '企業管理學系', '資料分析', 0.95),
  ('武垂玲', '企業管理學系', '數學與數值方法', 0.85),
  ('武垂玲', '企業管理學系', '管理與組織', 0.65),
  ('武垂玲', '企業管理學系', '能源', 0.6),
  ('王妙如', '企業管理學系', '管理與組織', 0.93),
  ('蔡汶君', '企業管理學系', '財務分析', 0.85),
  ('蔡汶君', '企業管理學系', '會計與財務', 0.75),
  ('蔡汶君', '企業管理學系', '數學與數值方法', 0.65),
  ('李元恕', '行銷學系', '行銷企劃', 0.93),
  ('何晉瑋', '行銷學系', '行銷企劃', 0.93),
  ('林豐智', '行銷學系', '管理與組織', 0.93),
  ('賴文祥', '行銷學系', '專案管理', 0.95),
  ('賴文祥', '行銷學系', '商業企劃', 0.88),
  ('賴文祥', '行銷學系', '管理與組織', 0.88),
  ('王婉禎', '行銷學系', '行銷企劃', 0.93),
  ('簡士超', '行銷學系', '行銷企劃', 0.93),
  ('簡士超', '行銷學系', '國際商務', 0.85),
  ('簡士超', '行銷學系', '管理與組織', 0.65),
  ('簡士超', '行銷學系', '平面設計', 0.6),
  ('簡士超', '行銷學系', '商業企劃', 0.6),
  ('丁美靜', '行銷學系', '行銷企劃', 0.93),
  ('丁美靜', '行銷學系', '管理與組織', 0.85),
  ('王郁彬', '行銷學系', '行銷企劃', 0.93),
  ('李悅端', '行銷學系', 'UI/UX 設計', 0.93),
  ('李悅端', '行銷學系', '資料視覺化', 0.9),
  ('李悅端', '行銷學系', '平面設計', 0.6),
  ('李悅端', '行銷學系', '簡報設計', 0.6),
  ('李悅端', '行銷學系', '研究方法', 0.6),
  ('李宜靜', '行銷學系', '行銷企劃', 0.93),
  ('李宜靜', '行銷學系', 'UI/UX 設計', 0.93),
  ('李宜靜', '行銷學系', '平面設計', 0.88),
  ('李宜靜', '行銷學系', '生成式 AI 應用', 0.8),
  ('葉俊亨', '行銷學系', '資料分析', 0.95),
  ('葉俊亨', '行銷學系', '行銷企劃', 0.93),
  ('葉俊亨', '行銷學系', 'UI/UX 設計', 0.9),
  ('葉俊亨', '行銷學系', '機器學習', 0.88),
  ('周進華', '行銷學系', '資料分析', 0.95),
  ('周進華', '行銷學系', '行銷企劃', 0.9),
  ('周進華', '行銷學系', 'Python', 0.85),
  ('周進華', '行銷學系', '程式設計基礎', 0.85),
  ('林建安', '行銷學系', '行銷企劃', 0.93),
  ('林建安', '行銷學系', '研究方法', 0.63),
  ('李律鋒', '行銷學系', '行銷企劃', 0.93),
  ('李律鋒', '行銷學系', '寫作與文案', 0.93),
  ('李律鋒', '行銷學系', '簡報設計', 0.6),
  ('陳婉淑', '統計學系', '統計', 0.95),
  ('陳婉淑', '統計學系', '資料分析', 0.6),
  ('李燊銘', '統計學系', '統計', 0.95),
  ('李燊銘', '統計學系', '數學與數值方法', 0.85),
  ('李燊銘', '統計學系', '會計與財務', 0.75),
  ('李燊銘', '統計學系', '問卷設計', 0.55),
  ('吳進家', '統計學系', '統計', 0.95),
  ('吳進家', '統計學系', '數學與數值方法', 0.85),
  ('林麗芬', '統計學系', '統計', 0.95),
  ('林麗芬', '統計學系', '會計與財務', 0.78),
  ('鍾冬川', '統計學系', '統計', 0.95),
  ('鍾冬川', '統計學系', '數學與數值方法', 0.65),
  ('吳榮彬', '統計學系', '統計', 0.95),
  ('吳榮彬', '統計學系', '問卷設計', 0.93),
  ('吳榮彬', '統計學系', '研究方法', 0.6),
  ('李仁佑', '統計學系', '統計', 0.95),
  ('劉峰旗', '統計學系', '統計', 0.95),
  ('劉峰旗', '統計學系', '財務分析', 0.85),
  ('劉峰旗', '統計學系', '資料分析', 0.8),
  ('劉峰旗', '統計學系', '會計與財務', 0.75),
  ('盧馬汀', '統計學系', '統計', 0.95),
  ('盧馬汀', '統計學系', '資料分析', 0.95),
  ('巫亮宏', '統計學系', '統計', 0.95),
  ('巫亮宏', '統計學系', '資料分析', 0.95),
  ('巫亮宏', '統計學系', '資料視覺化', 0.9),
  ('巫亮宏', '統計學系', '機器學習', 0.85),
  ('王俞凱', '統計學系', '統計', 0.95),
  ('王俞凱', '統計學系', '數學與數值方法', 0.85),
  ('廖揚立', '統計學系', '統計', 0.95),
  ('廖揚立', '統計學系', '機器學習', 0.95),
  ('杜昌燁', '統計學系', '機器學習', 0.95),
  ('杜昌燁', '統計學系', '數學與數值方法', 0.88),
  ('杜昌燁', '統計學系', '財務分析', 0.85),
  ('杜昌燁', '統計學系', '會計與財務', 0.75),
  ('賴暐婷', '統計學系', '統計', 0.88),
  ('蕭堯仁', '工業工程與系統管理學系', '專案管理', 0.95),
  ('蕭堯仁', '工業工程與系統管理學系', '管理與組織', 0.88),
  ('林棋瑋', '工業工程與系統管理學系', '工業與產品設計', 0.85),
  ('林棋瑋', '工業工程與系統管理學系', '管理與組織', 0.85),
  ('林棋瑋', '工業工程與系統管理學系', '專案管理', 0.7),
  ('唐國豪', '工業工程與系統管理學系', 'UI/UX 設計', 0.93),
  ('唐國豪', '工業工程與系統管理學系', '管理與組織', 0.65),
  ('唐國豪', '工業工程與系統管理學系', '專案管理', 0.55),
  ('王逸琦', '工業工程與系統管理學系', '管理與組織', 0.8),
  ('王逸琦', '工業工程與系統管理學系', '專案管理', 0.73),
  ('王逸琦', '工業工程與系統管理學系', '機械設計與製造', 0.7),
  ('王逸琦', '工業工程與系統管理學系', '數學與數值方法', 0.65),
  ('林暘桂', '工業工程與系統管理學系', '統計', 0.95),
  ('林暘桂', '工業工程與系統管理學系', '數學與數值方法', 0.88),
  ('林暘桂', '工業工程與系統管理學系', '專案管理', 0.7),
  ('林暘桂', '工業工程與系統管理學系', '研究方法', 0.6),
  ('楊士霆', '工業工程與系統管理學系', '資料分析', 0.95),
  ('楊士霆', '工業工程與系統管理學系', '機器學習', 0.85),
  ('楊士霆', '工業工程與系統管理學系', '管理與組織', 0.85),
  ('楊士霆', '工業工程與系統管理學系', '行銷企劃', 0.63),
  ('楊士霆', '工業工程與系統管理學系', '行動應用開發', 0.55),
  ('陳兆衡', '工業工程與系統管理學系', '管理與組織', 0.88),
  ('陳兆衡', '工業工程與系統管理學系', '機械設計與製造', 0.65),
  ('陳兆衡', '工業工程與系統管理學系', '英文溝通', 0.6),
  ('鍾健平', '工業工程與系統管理學系', '管理與組織', 0.88),
  ('鍾健平', '工業工程與系統管理學系', '專案管理', 0.73),
  ('鍾健平', '工業工程與系統管理學系', '數學與數值方法', 0.65),
  ('鍾健平', '工業工程與系統管理學系', '機器人與自動控制', 0.65),
  ('周哲維', '工業工程與系統管理學系', '資料分析', 0.95),
  ('周哲維', '工業工程與系統管理學系', '數學與數值方法', 0.88),
  ('周哲維', '工業工程與系統管理學系', '機械設計與製造', 0.65),
  ('周哲維', '工業工程與系統管理學系', '機器人與自動控制', 0.65),
  ('丘紀堇', '工業工程與系統管理學系', '工業與產品設計', 0.88),
  ('丘紀堇', '工業工程與系統管理學系', '平面設計', 0.6),
  ('蔡麗珍', '工業工程與系統管理學系', '專案管理', 0.95),
  ('蔡麗珍', '工業工程與系統管理學系', 'UI/UX 設計', 0.93),
  ('蔡麗珍', '工業工程與系統管理學系', 'SQL', 0.85),
  ('周育樂', '工業工程與系統管理學系', '數學與數值方法', 0.85),
  ('周育樂', '工業工程與系統管理學系', '專案管理', 0.73),
  ('周育樂', '工業工程與系統管理學系', '機器人與自動控制', 0.68),
  ('周育樂', '工業工程與系統管理學系', '管理與組織', 0.65),
  ('周育樂', '工業工程與系統管理學系', '機械設計與製造', 0.65),
  ('伍廷蔚', '工業工程與系統管理學系', '資料分析', 0.95),
  ('伍廷蔚', '工業工程與系統管理學系', '機器學習', 0.95),
  ('伍廷蔚', '工業工程與系統管理學系', '深度學習', 0.95),
  ('伍廷蔚', '工業工程與系統管理學系', '機械設計與製造', 0.65),
  ('伍廷蔚', '工業工程與系統管理學系', '機器人與自動控制', 0.65),
  ('王履梅', '工業工程與系統管理學系', '專案管理', 0.95),
  ('王履梅', '工業工程與系統管理學系', '資料分析', 0.95),
  ('王履梅', '工業工程與系統管理學系', '管理與組織', 0.68),
  ('王履梅', '工業工程與系統管理學系', '程式設計基礎', 0.6),
  ('王履梅', '工業工程與系統管理學系', '商業企劃', 0.6),
  ('莊文傑', '工業工程與系統管理學系', '管理與組織', 0.88),
  ('莊文傑', '工業工程與系統管理學系', '資料分析', 0.8),
  ('莊文傑', '工業工程與系統管理學系', '行銷企劃', 0.75),
  ('莊文傑', '工業工程與系統管理學系', '商業企劃', 0.6),
  ('楊文祿', '電子工程學系', '電子電路', 0.93),
  ('施仁斌', '電子工程學系', '材料與化工', 0.88),
  ('施仁斌', '電子工程學系', '電子電路', 0.73),
  ('施仁斌', '電子工程學系', '能源', 0.63),
  ('李景松', '電子工程學系', '電子電路', 0.93),
  ('李景松', '電子工程學系', '材料與化工', 0.6),
  ('李景松', '電子工程學系', '能源', 0.6),
  ('劉堂傑', '電子工程學系', '電子電路', 0.93),
  ('劉堂傑', '電子工程學系', '數學與數值方法', 0.85),
  ('簡鳳佐', '電子工程學系', '電子電路', 0.93),
  ('林宗志', '電子工程學系', '電子電路', 0.93),
  ('林宗志', '電子工程學系', '機器人與自動控制', 0.93),
  ('林宗志', '電子工程學系', '機器學習', 0.85),
  ('康宗貴', '電子工程學系', '電子電路', 0.9),
  ('鄭經華', '電子工程學系', '電子電路', 0.93),
  ('林成利', '電子工程學系', '電子電路', 0.93),
  ('林進發', '電子工程學系', '電子電路', 0.93),
  ('林進發', '電子工程學系', '機器人與自動控制', 0.9),
  ('林進發', '電子工程學系', '機器學習', 0.85),
  ('林進發', '電子工程學系', '嵌入式與物聯網', 0.65),
  ('楊炳章', '電子工程學系', '電子電路', 0.93),
  ('許恒壽', '電子工程學系', '電子電路', 0.93),
  ('許恒壽', '電子工程學系', '通訊與訊號處理', 0.65),
  ('王通温', '電子工程學系', '電子電路', 0.93),
  ('王通温', '電子工程學系', '嵌入式與物聯網', 0.93),
  ('王通温', '電子工程學系', '材料與化工', 0.88),
  ('王通温', '電子工程學系', '機器學習', 0.85),
  ('王通温', '電子工程學系', '雲端與網路', 0.65),
  ('王馭熊', '電子工程學系', '電子電路', 0.93),
  ('王馭熊', '電子工程學系', '材料與化工', 0.6),
  ('張一楠', '電子工程學系', '電子電路', 0.93),
  ('張一楠', '電子工程學系', '機械設計與製造', 0.65),
  ('何家淮', '電子工程學系', '專案管理', 0.95),
  ('何家淮', '電子工程學系', '電子電路', 0.93),
  ('何家淮', '電子工程學系', '嵌入式與物聯網', 0.9),
  ('何家淮', '電子工程學系', '航太與系統', 0.55),
  ('陳宗毅', '電子工程學系', '電子電路', 0.93),
  ('陳宗毅', '電子工程學系', '嵌入式與物聯網', 0.9),
  ('陳宗毅', '電子工程學系', '多媒體與影像', 0.85),
  ('陳宗毅', '電子工程學系', '機器學習', 0.85),
  ('陳宗毅', '電子工程學系', '作業系統與系統程式', 0.75),
  ('許騰仁', '電子工程學系', '電子電路', 0.9),
  ('許騰仁', '電子工程學系', '通訊與訊號處理', 0.9),
  ('許騰仁', '電子工程學系', '嵌入式與物聯網', 0.9),
  ('許騰仁', '電子工程學系', '機器學習', 0.85),
  ('許騰仁', '電子工程學系', '深度學習', 0.85),
  ('劉維正', '電子工程學系', '通訊與訊號處理', 0.9),
  ('楊鎮安', '電子工程學系', '電子電路', 0.93),
  ('楊鎮安', '電子工程學系', '資料結構與演算法', 0.9),
  ('楊鎮安', '電子工程學系', '機器學習', 0.85),
  ('楊鎮安', '電子工程學系', '深度學習', 0.85),
  ('邱創乾', '自動控制工程學系', '通訊與訊號處理', 0.93),
  ('邱創乾', '自動控制工程學系', '深度學習', 0.85),
  ('邱創乾', '自動控制工程學系', '多媒體與影像', 0.85),
  ('林賢龍', '自動控制工程學系', '通訊與訊號處理', 0.9),
  ('林賢龍', '自動控制工程學系', '機器人與自動控制', 0.75),
  ('洪三山', '自動控制工程學系', '電子電路', 0.93),
  ('洪三山', '自動控制工程學系', '機器人與自動控制', 0.9),
  ('洪三山', '自動控制工程學系', '嵌入式與物聯網', 0.68),
  ('洪三山', '自動控制工程學系', '通訊與訊號處理', 0.65),
  ('林昱成', '自動控制工程學系', '深度學習', 0.95),
  ('林昱成', '自動控制工程學系', '機器人與自動控制', 0.93),
  ('林昱成', '自動控制工程學系', '嵌入式與物聯網', 0.9),
  ('林昱成', '自動控制工程學系', '生成式 AI 應用', 0.9),
  ('林昱成', '自動控制工程學系', '機器學習', 0.88),
  ('鄒慶福', '自動控制工程學系', '電子電路', 0.73),
  ('鄒慶福', '自動控制工程學系', '機械設計與製造', 0.68),
  ('劉益瑞', '自動控制工程學系', '通訊與訊號處理', 0.9),
  ('劉益瑞', '自動控制工程學系', '多媒體與影像', 0.88),
  ('劉益瑞', '自動控制工程學系', '深度學習', 0.65),
  ('林育德', '自動控制工程學系', '機器學習', 0.95),
  ('林育德', '自動控制工程學系', '深度學習', 0.95),
  ('林育德', '自動控制工程學系', '通訊與訊號處理', 0.93),
  ('林育德', '自動控制工程學系', '嵌入式與物聯網', 0.93),
  ('林育德', '自動控制工程學系', '雲端與網路', 0.85),
  ('沈祖望', '自動控制工程學系', '機器學習', 0.88),
  ('沈祖望', '自動控制工程學系', '多媒體與影像', 0.88),
  ('沈祖望', '自動控制工程學系', '嵌入式與物聯網', 0.65),
  ('沈祖望', '自動控制工程學系', '機器人與自動控制', 0.65),
  ('林南州', '自動控制工程學系', '機器人與自動控制', 0.93),
  ('林南州', '自動控制工程學系', '數學與數值方法', 0.65),
  ('陳鏡崑', '自動控制工程學系', '資訊安全', 0.9),
  ('陳鏡崑', '自動控制工程學系', '電子電路', 0.9),
  ('陳鏡崑', '自動控制工程學系', '通訊與訊號處理', 0.68),
  ('廖本義', '自動控制工程學系', '通訊與訊號處理', 0.9),
  ('陳志成', '自動控制工程學系', '機器學習', 0.95),
  ('陳志成', '自動控制工程學系', '深度學習', 0.95),
  ('陳志成', '自動控制工程學系', '機器人與自動控制', 0.93),
  ('陳志成', '自動控制工程學系', '嵌入式與物聯網', 0.65),
  ('陳志成', '自動控制工程學系', '機械設計與製造', 0.65),
  ('秦群立', '自動控制工程學系', '嵌入式與物聯網', 0.9),
  ('秦群立', '自動控制工程學系', '機器學習', 0.88),
  ('秦群立', '自動控制工程學系', '多媒體與影像', 0.85),
  ('秦群立', '自動控制工程學系', '深度學習', 0.65),
  ('秦群立', '自動控制工程學系', '程式設計基礎', 0.6),
  ('徐永煜', '自動控制工程學系', '深度學習', 0.95),
  ('徐永煜', '自動控制工程學系', '機器學習', 0.88),
  ('徐永煜', '自動控制工程學系', '多媒體與影像', 0.85),
  ('徐永煜', '自動控制工程學系', '嵌入式與物聯網', 0.65),
  ('謝男凱', '自動控制工程學系', '機械設計與製造', 0.93),
  ('謝男凱', '自動控制工程學系', '機器人與自動控制', 0.93),
  ('謝男凱', '自動控制工程學系', '嵌入式與物聯網', 0.9),
  ('謝男凱', '自動控制工程學系', '雲端與網路', 0.65),
  ('林上智', '自動控制工程學系', '機器學習', 0.85),
  ('林上智', '自動控制工程學系', '數學與數值方法', 0.85),
  ('林上智', '自動控制工程學系', '航太與系統', 0.75),
  ('林上智', '自動控制工程學系', '機器人與自動控制', 0.68),
  ('林上智', '自動控制工程學系', '機械設計與製造', 0.65),
  ('黃清輝', '自動控制工程學系', '機器學習', 0.85),
  ('黃清輝', '自動控制工程學系', '深度學習', 0.8),
  ('黃清輝', '自動控制工程學系', '航太與系統', 0.75),
  ('黃清輝', '自動控制工程學系', '機器人與自動控制', 0.7),
  ('黃清輝', '自動控制工程學系', '機械設計與製造', 0.7),
  ('劉承勳', '自動控制工程學系', '電子電路', 0.73),
  ('劉承勳', '自動控制工程學系', '機械設計與製造', 0.68),
  ('李峰吉', '自動控制工程學系', '機器人與自動控制', 0.93),
  ('李峰吉', '自動控制工程學系', '機械設計與製造', 0.65),
  ('李峰吉', '自動控制工程學系', '能源', 0.6),
  ('彭嘉美', '通訊工程學系', '電子電路', 0.93),
  ('彭嘉美', '通訊工程學系', '通訊與訊號處理', 0.75),
  ('彭嘉美', '通訊工程學系', '嵌入式與物聯網', 0.65),
  ('陸清達', '通訊工程學系', '嵌入式與物聯網', 0.9),
  ('陸清達', '通訊工程學系', '通訊與訊號處理', 0.9),
  ('陸清達', '通訊工程學系', '機器學習', 0.88),
  ('陸清達', '通訊工程學系', '多媒體與影像', 0.88),
  ('陸清達', '通訊工程學系', '雲端與網路', 0.65),
  ('袁世一', '通訊工程學系', '作業系統與系統程式', 0.95),
  ('袁世一', '通訊工程學系', '嵌入式與物聯網', 0.93),
  ('袁世一', '通訊工程學系', '電子電路', 0.9),
  ('袁世一', '通訊工程學系', '程式設計基礎', 0.85),
  ('蔡淵裕', '通訊工程學系', '資訊安全', 0.9),
  ('蔡淵裕', '通訊工程學系', '多媒體與影像', 0.88),
  ('楊豐瑞', '通訊工程學系', '雲端與網路', 0.85),
  ('楊豐瑞', '通訊工程學系', '機器學習', 0.85),
  ('楊豐瑞', '通訊工程學系', '作業系統與系統程式', 0.75),
  ('楊豐瑞', '通訊工程學系', '通訊與訊號處理', 0.65),
  ('辛正和', '通訊工程學系', '深度學習', 0.95),
  ('辛正和', '通訊工程學系', '機器學習', 0.95),
  ('辛正和', '通訊工程學系', '通訊與訊號處理', 0.93),
  ('辛正和', '通訊工程學系', '多媒體與影像', 0.88),
  ('尤正祺', '通訊工程學系', '電子電路', 0.93),
  ('尤正祺', '通訊工程學系', '材料與化工', 0.85),
  ('尤正祺', '通訊工程學系', '通訊與訊號處理', 0.68),
  ('趙啟時', '通訊工程學系', '資訊安全', 0.9),
  ('趙啟時', '通訊工程學系', '雲端與網路', 0.88),
  ('趙啟時', '通訊工程學系', '機器學習', 0.85),
  ('趙啟時', '通訊工程學系', '程式設計基礎', 0.85),
  ('陳益生', '通訊工程學系', '通訊與訊號處理', 0.93),
  ('林維崙', '通訊工程學系', '深度學習', 0.95),
  ('林維崙', '通訊工程學系', '通訊與訊號處理', 0.93),
  ('林維崙', '通訊工程學系', '機器人與自動控制', 0.9),
  ('林維崙', '通訊工程學系', '嵌入式與物聯網', 0.9),
  ('林維崙', '通訊工程學系', '機器學習', 0.85),
  ('陳家豪', '通訊工程學系', '電子電路', 0.93),
  ('陳家豪', '通訊工程學系', '通訊與訊號處理', 0.68),
  ('蔡昂勳', '通訊工程學系', '通訊與訊號處理', 0.93),
  ('蔡昂勳', '通訊工程學系', '雲端與網路', 0.88),
  ('蔡昂勳', '通訊工程學系', '機器學習', 0.85),
  ('蔡昂勳', '通訊工程學系', '航太與系統', 0.78),
  ('朱嘯秋', '通訊工程學系', '通訊與訊號處理', 0.93),
  ('朱嘯秋', '通訊工程學系', '雲端與網路', 0.85),
  ('呂威甫', '通訊工程學系', '機器學習', 0.95),
  ('呂威甫', '通訊工程學系', '資料結構與演算法', 0.93),
  ('呂威甫', '通訊工程學系', '雲端與網路', 0.85),
  ('呂威甫', '通訊工程學系', '數學與數值方法', 0.85),
  ('呂威甫', '通訊工程學系', '嵌入式與物聯網', 0.65),
  ('何子豪', '通訊工程學系', '電子電路', 0.93),
  ('何子豪', '通訊工程學系', '通訊與訊號處理', 0.65),
  ('謝瑞民', '通訊工程學系', '資料結構與演算法', 0.9),
  ('謝瑞民', '通訊工程學系', 'SQL', 0.85),
  ('謝瑞民', '通訊工程學系', '數學與數值方法', 0.85),
  ('陳紀翰', '通訊工程學系', '嵌入式與物聯網', 0.93),
  ('陳紀翰', '通訊工程學系', '通訊與訊號處理', 0.9),
  ('陳紀翰', '通訊工程學系', '機器學習', 0.88),
  ('陳紀翰', '通訊工程學系', '深度學習', 0.85),
  ('李秉乾', '土木工程學系', '土木與營建', 0.93),
  ('李秉乾', '土木工程學系', '環境與水利', 0.7),
  ('林保宏', '土木工程學系', '專案管理', 0.95),
  ('林保宏', '土木工程學系', '土木與營建', 0.93),
  ('林保宏', '土木工程學系', '資料分析', 0.8),
  ('林保宏', '土木工程學系', '管理與組織', 0.68),
  ('林保宏', '土木工程學系', '建築與空間設計', 0.6),
  ('林正紋', '土木工程學系', '土木與營建', 0.9),
  ('林正紋', '土木工程學系', '機器人與自動控制', 0.9),
  ('林正紋', '土木工程學系', '機器學習', 0.85),
  ('林正紋', '土木工程學系', '專案管理', 0.7),
  ('林正紋', '土木工程學系', '管理與組織', 0.65),
  ('張智元', '土木工程學系', '土木與營建', 0.93),
  ('張智元', '土木工程學系', '法律與法規', 0.85),
  ('張智元', '土木工程學系', '專案管理', 0.7),
  ('張智元', '土木工程學系', '建築與空間設計', 0.7),
  ('張智元', '土木工程學系', '管理與組織', 0.68),
  ('林威延', '土木工程學系', '土木與營建', 0.93),
  ('林威延', '土木工程學系', '專案管理', 0.7),
  ('林威延', '土木工程學系', '資料視覺化', 0.68),
  ('林威延', '土木工程學系', '管理與組織', 0.65),
  ('林威延', '土木工程學系', '建築與空間設計', 0.63),
  ('紀昭銘', '土木工程學系', '土木與營建', 0.93),
  ('紀昭銘', '土木工程學系', '數學與數值方法', 0.85),
  ('賴哲儇', '土木工程學系', '機器學習', 0.95),
  ('賴哲儇', '土木工程學系', '環境與水利', 0.7),
  ('賴哲儇', '土木工程學系', '資料視覺化', 0.68),
  ('賴哲儇', '土木工程學系', '土木與營建', 0.63),
  ('賴哲儇', '土木工程學系', '建築與空間設計', 0.6),
  ('莊財福', '土木工程學系', '土木與營建', 0.93),
  ('莊財福', '土木工程學系', '數學與數值方法', 0.85),
  ('莊財福', '土木工程學系', '建築與空間設計', 0.7),
  ('莊財福', '土木工程學系', '多媒體與影像', 0.6),
  ('林喻峰', '土木工程學系', '土木與營建', 0.93),
  ('曾韋禎', '土木工程學系', '土木與營建', 0.93),
  ('曾韋禎', '土木工程學系', '能源', 0.7),
  ('劉至軒', '土木工程學系', '土木與營建', 0.93),
  ('劉至軒', '土木工程學系', '數學與數值方法', 0.85),
  ('劉至軒', '土木工程學系', '環境與水利', 0.7),
  ('楊晏瑜', '土木工程學系', '土木與營建', 0.93),
  ('楊晏瑜', '土木工程學系', '數學與數值方法', 0.88),
  ('張庭維', '土木工程學系', '土木與營建', 0.93),
  ('張庭維', '土木工程學系', '數學與數值方法', 0.85),
  ('張庭維', '土木工程學系', '機器人與自動控制', 0.6),
  ('紀懿恩', '土木工程學系', '土木與營建', 0.93),
  ('闕帝丰', '外國語文學系', '寫作與文案', 0.73),
  ('闕帝丰', '外國語文學系', '英文溝通', 0.6),
  ('闕帝丰', '外國語文學系', '英文寫作', 0.58),
  ('董綺安', '外國語文學系', '英文寫作', 0.95),
  ('董綺安', '外國語文學系', '英文溝通', 0.63),
  ('周玉楨', '外國語文學系', '英文溝通', 0.63),
  ('蔡明秀', '外國語文學系', '英文溝通', 0.88),
  ('蔡明秀', '外國語文學系', '英文寫作', 0.88),
  ('蔡明秀', '外國語文學系', '國際商務', 0.58),
  ('劉川豪', '外國語文學系', '寫作與文案', 0.73),
  ('劉川豪', '外國語文學系', '英文溝通', 0.63),
  ('劉川豪', '外國語文學系', '英文寫作', 0.58),
  ('洪筱婷', '外國語文學系', '寫作與文案', 0.73),
  ('洪筱婷', '外國語文學系', '英文溝通', 0.6),
  ('劉怡君', '外國語文學系', '英文寫作', 0.85),
  ('劉怡君', '外國語文學系', '寫作與文案', 0.73),
  ('陳萱芳', '外國語文學系', '英文寫作', 0.95),
  ('陳萱芳', '外國語文學系', '英文溝通', 0.88),
  ('謝宏濱', '外國語文學系', '法律與法規', 0.88),
  ('謝宏濱', '外國語文學系', '英文寫作', 0.88),
  ('謝宏濱', '外國語文學系', '經濟分析', 0.85),
  ('鄭慧如', '中國文學系', '寫作與文案', 0.73),
  ('張瑞芬', '中國文學系', '寫作與文案', 0.73),
  ('余風', '中國文學系', '平面設計', 0.85),
  ('余風', '中國文學系', '研究方法', 0.6),
  ('余風', '中國文學系', '多媒體與影像', 0.6),
  ('余風', '中國文學系', '寫作與文案', 0.53),
  ('李寶玲', '中國文學系', '寫作與文案', 0.73),
  ('劉仲倫', '中國文學系', '寫作與文案', 0.7),
  ('劉仲倫', '中國文學系', '多媒體與影像', 0.63),
  ('劉仲倫', '中國文學系', '商業企劃', 0.6),
  ('梁雅英', '中國文學系', '寫作與文案', 0.93),
  ('李綉玲', '中國文學系', '寫作與文案', 0.73),
  ('徐培晃', '中國文學系', '寫作與文案', 0.73),
  ('楊美美', '中國文學系', '寫作與文案', 0.73),
  ('許宜珮', '建築學士學位學程', '建築與空間設計', 0.93),
  ('許宜珮', '建築學士學位學程', '環境與水利', 0.73),
  ('張莉欣', '建築學士學位學程', '建築與空間設計', 0.93),
  ('張莉欣', '建築學士學位學程', '環境與水利', 0.73),
  ('Lorena Alessio', '建築學士學位學程', '建築與空間設計', 0.93),
  ('林葳', '建築學士學位學程', '建築與空間設計', 0.93),
  ('林葳', '建築學士學位學程', '環境與水利', 0.7),
  ('林葳', '建築學士學位學程', '通訊與訊號處理', 0.65),
  ('李英弘', '建築學士學位學程', '建築與空間設計', 0.9),
  ('李英弘', '建築學士學位學程', '管理與組織', 0.68),
  ('黎淑婷', '建築學士學位學程', '建築與空間設計', 0.93),
  ('黎淑婷', '建築學士學位學程', '平面設計', 0.63),
  ('林佳慧', '建築學士學位學程', '建築與空間設計', 0.93),
  ('林佳慧', '建築學士學位學程', '環境與水利', 0.73),
  ('林佳慧', '建築學士學位學程', '專案管理', 0.7),
  ('林佳慧', '建築學士學位學程', 'UI/UX 設計', 0.6),
  ('林佳慧', '建築學士學位學程', '材料與化工', 0.55),
  ('李元榮', '建築學士學位學程', '建築與空間設計', 0.93),
  ('李元榮', '建築學士學位學程', 'UI/UX 設計', 0.9),
  ('宋玉真', '建築學士學位學程', '建築與空間設計', 0.93),
  ('宋玉真', '建築學士學位學程', '研究方法', 0.6),
  ('盛郁庭', '建築學士學位學程', '建築與空間設計', 0.9),
  ('盛郁庭', '建築學士學位學程', '機器人與自動控制', 0.9),
  ('盛郁庭', '建築學士學位學程', '工業與產品設計', 0.63),
  ('林幸長', '建築學士學位學程', '建築與空間設計', 0.93),
  ('林幸長', '建築學士學位學程', '平面設計', 0.6),
  ('顏貽祥', '建築學士學位學程', '深度學習', 0.95),
  ('顏貽祥', '建築學士學位學程', '機器人與自動控制', 0.9),
  ('顏貽祥', '建築學士學位學程', '多媒體與影像', 0.88),
  ('顏貽祥', '建築學士學位學程', '數學與數值方法', 0.85),
  ('顏貽祥', '建築學士學位學程', '資料結構與演算法', 0.78),
  ('林衍良', '建築學士學位學程', '建築與空間設計', 0.93),
  ('林衍良', '建築學士學位學程', '數學與數值方法', 0.85),
  ('林衍良', '建築學士學位學程', '環境與水利', 0.73),
  ('林衍良', '建築學士學位學程', '能源', 0.6),
  ('蕭俊碩', '建築學士學位學程', '建築與空間設計', 0.93),
  ('蕭俊碩', '建築學士學位學程', '多媒體與影像', 0.85),
  ('蕭俊碩', '建築學士學位學程', '工業與產品設計', 0.6),
  ('蕭俊碩', '建築學士學位學程', 'UI/UX 設計', 0.6),
  ('蕭俊碩', '建築學士學位學程', '環境與水利', 0.55),
  ('吳保寬', '建築學士學位學程', '機器學習', 0.95),
  ('吳保寬', '建築學士學位學程', '建築與空間設計', 0.93),
  ('吳保寬', '建築學士學位學程', '多媒體與影像', 0.85),
  ('吳保寬', '建築學士學位學程', '資料分析', 0.8),
  ('吳保寬', '建築學士學位學程', '資料視覺化', 0.65),
  ('謝銘峯', '建築學士學位學程', '建築與空間設計', 0.93),
  ('謝銘峯', '建築學士學位學程', 'UI/UX 設計', 0.9),
  ('謝銘峯', '建築學士學位學程', '商業企劃', 0.63),
  ('謝銘峯', '建築學士學位學程', '工業與產品設計', 0.6),
  ('趙又嬋', '建築學士學位學程', '建築與空間設計', 0.93),
  ('趙又嬋', '建築學士學位學程', '環境與水利', 0.73),
  ('曾韋翔', '建築學士學位學程', '建築與空間設計', 0.93),
  ('曾韋翔', '建築學士學位學程', '研究方法', 0.6),
  ('高敬賢', '建築學士學位學程', '建築與空間設計', 0.93),
  ('Nicolas Marechal', '建築學士學位學程', 'UI/UX 設計', 0.9),
  ('Nicolas Marechal', '建築學士學位學程', '多媒體與影像', 0.85),
  ('張芸翠', '建築學士學位學程', '建築與空間設計', 0.93),
  ('張芸翠', '建築學士學位學程', '環境與水利', 0.7),
  ('張芸翠', '建築學士學位學程', '資料視覺化', 0.65),
  ('張芸翠', '建築學士學位學程', '土木與營建', 0.6),
  ('呂耀中', '建築學士學位學程', '建築與空間設計', 0.93),
  ('呂耀中', '建築學士學位學程', 'UI/UX 設計', 0.6),
  ('呂耀中', '建築學士學位學程', '平面設計', 0.6),
  ('呂耀中', '建築學士學位學程', '商業企劃', 0.6),
  ('呂耀中', '建築學士學位學程', '環境與水利', 0.55),
  ('宋非凡', '建築學士學位學程', '建築與空間設計', 0.9),
  ('宋非凡', '建築學士學位學程', '機器人與自動控制', 0.9),
  ('宋非凡', '建築學士學位學程', '工業與產品設計', 0.6),
  ('周郁森', '建築學士學位學程', '建築與空間設計', 0.93),
  ('劉柏昇', '建築學士學位學程', '建築與空間設計', 0.93),
  ('劉柏昇', '建築學士學位學程', '土木與營建', 0.9),
  ('劉柏昇', '建築學士學位學程', '材料與化工', 0.88),
  ('劉柏昇', '建築學士學位學程', '數學與數值方法', 0.85),
  ('劉柏昇', '建築學士學位學程', '資料分析', 0.8),
  ('凃昭伃', '建築學士學位學程', '建築與空間設計', 0.93),
  ('凃昭伃', '建築學士學位學程', '土木與營建', 0.93),
  ('梁君輝', '建築學士學位學程', '深度學習', 0.95),
  ('梁君輝', '建築學士學位學程', '機器學習', 0.95),
  ('梁君輝', '建築學士學位學程', '嵌入式與物聯網', 0.9),
  ('梁君輝', '建築學士學位學程', '程式設計基礎', 0.88),
  ('梁君輝', '建築學士學位學程', 'Python', 0.85),
  ('江向才', '會計學系', '會計與財務', 0.95),
  ('江向才', '會計學系', '財務分析', 0.88),
  ('江向才', '會計學系', '管理與組織', 0.85),
  ('江向才', '會計學系', '國際商務', 0.85),
  ('張森河', '會計學系', '會計與財務', 0.95),
  ('張森河', '會計學系', '財務分析', 0.88),
  ('張森河', '會計學系', '管理與組織', 0.88),
  ('翁慈青', '會計學系', '會計與財務', 0.95),
  ('翁慈青', '會計學系', '管理與組織', 0.85),
  ('翁慈青', '會計學系', '財務分析', 0.6),
  ('盧鈺欣', '會計學系', '會計與財務', 0.95),
  ('盧鈺欣', '會計學系', '機器學習', 0.85),
  ('盧鈺欣', '會計學系', '資料分析', 0.8),
  ('盧鈺欣', '會計學系', '財務分析', 0.6),
  ('盧鈺欣', '會計學系', '資訊安全', 0.5),
  ('陳光政', '會計學系', '會計與財務', 0.95),
  ('陳光政', '會計學系', '財務分析', 0.6),
  ('林嬌能', '會計學系', '會計與財務', 0.95),
  ('林嬌能', '會計學系', '財務分析', 0.6),
  ('黃娟娟', '會計學系', '會計與財務', 0.95),
  ('黃娟娟', '會計學系', '財務分析', 0.6),
  ('施念恕', '會計學系', '會計與財務', 0.95),
  ('施念恕', '會計學系', '財務分析', 0.6),
  ('施念恕', '會計學系', '管理與組織', 0.6),
  ('高惠松', '會計學系', '會計與財務', 0.95),
  ('高惠松', '會計學系', '管理與組織', 0.85),
  ('高惠松', '會計學系', '機器學習', 0.85),
  ('高惠松', '會計學系', '財務分析', 0.6),
  ('曹秀惠', '會計學系', '會計與財務', 0.95),
  ('曹秀惠', '會計學系', '管理與組織', 0.65),
  ('曹秀惠', '會計學系', '財務分析', 0.6),
  ('曹秀惠', '會計學系', '資訊安全', 0.5),
  ('吳東憲', '會計學系', '會計與財務', 0.95),
  ('吳東憲', '會計學系', '資訊安全', 0.5),
  ('王文聖', '會計學系', '管理與組織', 0.88),
  ('王文聖', '會計學系', '財務分析', 0.85),
  ('王文聖', '會計學系', '會計與財務', 0.78),
  ('林書賢', '會計學系', '會計與財務', 0.95),
  ('林書賢', '會計學系', '管理與組織', 0.88),
  ('林書賢', '會計學系', '財務分析', 0.6),
  ('吳周燕', '會計學系', '管理與組織', 0.85),
  ('吳周燕', '會計學系', '會計與財務', 0.78),
  ('吳周燕', '會計學系', '財務分析', 0.63),
  ('吳周燕', '會計學系', '環境與水利', 0.55),
  ('陳品如', '會計學系', '會計與財務', 0.95),
  ('李慧慈', '會計學系', '會計與財務', 0.95),
  ('李慧慈', '會計學系', '財務分析', 0.88),
  ('伍大開', '會計學系', '會計與財務', 0.95),
  ('伍大開', '會計學系', '經濟分析', 0.88),
  ('伍大開', '會計學系', '法律與法規', 0.85),
  ('伍大開', '會計學系', '統計', 0.85),
  ('楊明晶', '財務金融學系', '財務分析', 0.88),
  ('楊明晶', '財務金融學系', '國際商務', 0.88),
  ('楊明晶', '財務金融學系', '會計與財務', 0.78),
  ('吳仰哲', '財務金融學系', '深度學習', 0.95),
  ('吳仰哲', '財務金融學系', '財務分析', 0.88),
  ('吳仰哲', '財務金融學系', '會計與財務', 0.78),
  ('吳仰哲', '財務金融學系', '管理與組織', 0.65),
  ('陳清和', '財務金融學系', '財務分析', 0.88),
  ('陳清和', '財務金融學系', '經濟分析', 0.85),
  ('陳清和', '財務金融學系', '會計與財務', 0.75),
  ('李君屏', '財務金融學系', '財務分析', 0.88),
  ('李君屏', '財務金融學系', '會計與財務', 0.78),
  ('李君屏', '財務金融學系', '管理與組織', 0.65),
  ('洪偉峰', '財務金融學系', '財務分析', 0.88),
  ('洪偉峰', '財務金融學系', '會計與財務', 0.78),
  ('洪偉峰', '財務金融學系', '機器學習', 0.65),
  ('王佳真', '財務金融學系', '財務分析', 0.88),
  ('王佳真', '財務金融學系', '國際商務', 0.85),
  ('王佳真', '財務金融學系', '會計與財務', 0.78),
  ('劉炳麟', '財務金融學系', '財務分析', 0.88),
  ('劉炳麟', '財務金融學系', '統計', 0.85),
  ('劉炳麟', '財務金融學系', '會計與財務', 0.78),
  ('蔡函芳', '財務金融學系', '會計與財務', 0.95),
  ('蔡函芳', '財務金融學系', '財務分析', 0.88),
  ('蔡函芳', '財務金融學系', '管理與組織', 0.85),
  ('李宗儒', '財務金融學系', '機器學習', 0.95),
  ('李宗儒', '財務金融學系', '資料分析', 0.95),
  ('李宗儒', '財務金融學系', '會計與財務', 0.78),
  ('李宗儒', '財務金融學系', '財務分析', 0.63),
  ('劉峰旗', '財務金融學系', '統計', 0.95),
  ('劉峰旗', '財務金融學系', '財務分析', 0.85),
  ('劉峰旗', '財務金融學系', '資料分析', 0.8),
  ('劉峰旗', '財務金融學系', '會計與財務', 0.75),
  ('陳宗佑', '財務金融學系', '財務分析', 0.88),
  ('陳宗佑', '財務金融學系', '會計與財務', 0.78),
  ('陳宗佑', '財務金融學系', '數學與數值方法', 0.65),
  ('陳麗君', '財務金融學系', '財務分析', 0.88),
  ('陳麗君', '財務金融學系', '會計與財務', 0.78),
  ('陳麗君', '財務金融學系', '數學與數值方法', 0.68),
  ('陳麗君', '財務金融學系', '經濟分析', 0.6),
  ('莊明哲', '財務金融學系', '財務分析', 0.88),
  ('莊明哲', '財務金融學系', '會計與財務', 0.78),
  ('莊明哲', '財務金融學系', '數學與數值方法', 0.68),
  ('謝依婷', '財務金融學系', '會計與財務', 0.95),
  ('謝依婷', '財務金融學系', '財務分析', 0.88),
  ('謝金育', '財務金融學系', '深度學習', 0.95),
  ('謝金育', '財務金融學系', '財務分析', 0.63),
  ('謝金育', '財務金融學系', '資料分析', 0.6),
  ('武氏紅芳', '財務金融學系', '管理與組織', 0.88),
  ('武氏紅芳', '財務金融學系', '財務分析', 0.85),
  ('武氏紅芳', '財務金融學系', '專案管理', 0.55),
  ('黃迦怡', '財務金融學系', '資料分析', 0.95),
  ('黃迦怡', '財務金融學系', '財務分析', 0.88),
  ('黃迦怡', '財務金融學系', '經濟分析', 0.85),
  ('黃迦怡', '財務金融學系', '會計與財務', 0.78),
  ('廖文如', '財務金融學系', '統計', 0.95),
  ('廖文如', '財務金融學系', '財務分析', 0.88),
  ('廖文如', '財務金融學系', 'Python', 0.85),
  ('廖文如', '財務金融學系', '管理與組織', 0.85),
  ('廖文如', '財務金融學系', '會計與財務', 0.78),
  ('劉孟宜', '財務金融學系', '財務分析', 0.88),
  ('劉孟宜', '財務金融學系', '會計與財務', 0.78),
  ('林家仰', '財務金融學系', '經濟分析', 0.88),
  ('林家仰', '財務金融學系', '統計', 0.85),
  ('林家仰', '財務金融學系', '資料分析', 0.8),
  ('林家仰', '財務金融學系', '研究方法', 0.6),
  ('陳珮瀅', '財務金融學系', '會計與財務', 0.95),
  ('陳珮瀅', '財務金融學系', '財務分析', 0.88),
  ('陳珮瀅', '財務金融學系', '管理與組織', 0.85),
  ('王鈺仁', '財務金融學系', '資料分析', 0.95),
  ('王鈺仁', '財務金融學系', '資料視覺化', 0.9),
  ('王鈺仁', '財務金融學系', '財務分析', 0.88),
  ('王鈺仁', '財務金融學系', '統計', 0.85),
  ('王鈺仁', '財務金融學系', '數學與數值方法', 0.85),
  ('曾鼎翔', '國際經營與貿易學系', '行銷企劃', 0.93),
  ('曾鼎翔', '國際經營與貿易學系', '國際商務', 0.85),
  ('楊明憲', '國際經營與貿易學系', '經濟分析', 0.88),
  ('楊明憲', '國際經營與貿易學系', '國際商務', 0.88),
  ('江怡蒨', '國際經營與貿易學系', '國際商務', 0.85),
  ('江怡蒨', '國際經營與貿易學系', '會計與財務', 0.75),
  ('江怡蒨', '國際經營與貿易學系', '財務分析', 0.6),
  ('梁馨予', '國際經營與貿易學系', '財務分析', 0.88),
  ('梁馨予', '國際經營與貿易學系', '管理與組織', 0.88),
  ('梁馨予', '國際經營與貿易學系', '會計與財務', 0.78),
  ('許鈺珮', '國際經營與貿易學系', '經濟分析', 0.88),
  ('許鈺珮', '國際經營與貿易學系', '國際商務', 0.85),
  ('許鈺珮', '國際經營與貿易學系', '數學與數值方法', 0.85),
  ('邱世寬', '國際經營與貿易學系', '管理與組織', 0.88),
  ('邱世寬', '國際經營與貿易學系', '商業企劃', 0.85),
  ('邱世寬', '國際經營與貿易學系', '國際商務', 0.85),
  ('林呈昱', '國際經營與貿易學系', '行銷企劃', 0.93),
  ('林呈昱', '國際經營與貿易學系', '管理與組織', 0.65),
  ('吳廣文', '國際經營與貿易學系', '行銷企劃', 0.93),
  ('吳廣文', '國際經營與貿易學系', '國際商務', 0.85),
  ('吳文臨', '國際經營與貿易學系', '財務分析', 0.88),
  ('吳文臨', '國際經營與貿易學系', '國際商務', 0.88),
  ('吳文臨', '國際經營與貿易學系', '會計與財務', 0.78),
  ('劉翁世昆', '國際經營與貿易學系', '國際商務', 0.88),
  ('劉翁世昆', '國際經營與貿易學系', '管理與組織', 0.65),
  ('劉翁世昆', '國際經營與貿易學系', '經濟分析', 0.6),
  ('劉翁世昆', '國際經營與貿易學系', '行銷企劃', 0.6),
  ('劉翁世昆', '國際經營與貿易學系', '專案管理', 0.55),
  ('黃秀英', '國際經營與貿易學系', '行銷企劃', 0.9),
  ('黃秀英', '國際經營與貿易學系', '研究方法', 0.9),
  ('黃秀英', '國際經營與貿易學系', '國際商務', 0.88),
  ('黃秀英', '國際經營與貿易學系', '經濟分析', 0.6),
  ('邱安安', '國際經營與貿易學系', '會計與財務', 0.95),
  ('邱安安', '國際經營與貿易學系', '財務分析', 0.88),
  ('邱安安', '國際經營與貿易學系', '管理與組織', 0.88),
  ('董正玫', '國際經營與貿易學系', '行銷企劃', 0.9),
  ('董正玫', '國際經營與貿易學系', '商業企劃', 0.88),
  ('董正玫', '國際經營與貿易學系', '經濟分析', 0.85),
  ('董正玫', '國際經營與貿易學系', '管理與組織', 0.85),
  ('葉敬軒', '國際經營與貿易學系', '行銷企劃', 0.93),
  ('葉敬軒', '國際經營與貿易學系', '國際商務', 0.85),
  ('葉敬軒', '國際經營與貿易學系', '管理與組織', 0.65),
  ('劉世慶', '國際經營與貿易學系', '管理與組織', 0.93),
  ('劉世慶', '國際經營與貿易學系', '國際商務', 0.85),
  ('江成欣', '國際經營與貿易學系', '國際商務', 0.85),
  ('江成欣', '國際經營與貿易學系', '資料分析', 0.83),
  ('江成欣', '國際經營與貿易學系', '行銷企劃', 0.78),
  ('江成欣', '國際經營與貿易學系', '研究方法', 0.6),
  ('江成欣', '國際經營與貿易學系', '法律與法規', 0.5),
  ('林冠文', '國際經營與貿易學系', '行銷企劃', 0.93),
  ('林冠文', '國際經營與貿易學系', '國際商務', 0.88),
  ('林冠文', '國際經營與貿易學系', '管理與組織', 0.68),
  ('陳倩儀', '國際經營與貿易學系', '國際商務', 0.88),
  ('陳倩儀', '國際經營與貿易學系', '商業企劃', 0.85),
  ('陳倩儀', '國際經營與貿易學系', '會計與財務', 0.78),
  ('陳倩儀', '國際經營與貿易學系', '管理與組織', 0.65),
  ('陳倩儀', '國際經營與貿易學系', '財務分析', 0.63),
  ('商瓈丹', '國際經營與貿易學系', '資料分析', 0.95),
  ('商瓈丹', '國際經營與貿易學系', '經濟分析', 0.85),
  ('林介勝', '國際經營與貿易學系', '管理與組織', 0.93),
  ('林介勝', '國際經營與貿易學系', '國際商務', 0.85),
  ('蔡忠杓', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('周至宏', '機械與電腦輔助工程學系', '機器人與自動控制', 0.93),
  ('周至宏', '機械與電腦輔助工程學系', '機器學習', 0.85),
  ('周至宏', '機械與電腦輔助工程學系', '數學與數值方法', 0.85),
  ('周至宏', '機械與電腦輔助工程學系', '機械設計與製造', 0.65),
  ('周至宏', '機械與電腦輔助工程學系', '專案管理', 0.55),
  ('黃錦煌', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('黃錦煌', '機械與電腦輔助工程學系', '材料與化工', 0.85),
  ('黃錦煌', '機械與電腦輔助工程學系', '電子電路', 0.73),
  ('黃錦煌', '機械與電腦輔助工程學系', '通訊與訊號處理', 0.65),
  ('王啟昌', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('王啟昌', '機械與電腦輔助工程學系', '電子電路', 0.7),
  ('羅致卿', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('羅致卿', '機械與電腦輔助工程學系', '機器人與自動控制', 0.68),
  ('羅致卿', '機械與電腦輔助工程學系', '數學與數值方法', 0.65),
  ('劉顯光', '機械與電腦輔助工程學系', '材料與化工', 0.88),
  ('劉顯光', '機械與電腦輔助工程學系', '電子電路', 0.7),
  ('劉顯光', '機械與電腦輔助工程學系', '機械設計與製造', 0.65),
  ('林孟儒', '機械與電腦輔助工程學系', '電子電路', 0.73),
  ('林孟儒', '機械與電腦輔助工程學系', '機械設計與製造', 0.68),
  ('彭信舒', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('彭信舒', '機械與電腦輔助工程學系', '工業與產品設計', 0.85),
  ('王坤卿', '機械與電腦輔助工程學系', '通訊與訊號處理', 0.9),
  ('王坤卿', '機械與電腦輔助工程學系', '嵌入式與物聯網', 0.9),
  ('王坤卿', '機械與電腦輔助工程學系', '機器學習', 0.85),
  ('王坤卿', '機械與電腦輔助工程學系', '深度學習', 0.85),
  ('王坤卿', '機械與電腦輔助工程學系', '雲端與網路', 0.65),
  ('袁長安', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('袁長安', '機械與電腦輔助工程學系', '電子電路', 0.9),
  ('袁長安', '機械與電腦輔助工程學系', '數學與數值方法', 0.85),
  ('袁長安', '機械與電腦輔助工程學系', '機器學習', 0.85),
  ('袁長安', '機械與電腦輔助工程學系', '專案管理', 0.7),
  ('陳秋宏', '機械與電腦輔助工程學系', '機器人與自動控制', 0.93),
  ('陳秋宏', '機械與電腦輔助工程學系', '生成式 AI 應用', 0.9),
  ('陳秋宏', '機械與電腦輔助工程學系', '機器學習', 0.88),
  ('陳秋宏', '機械與電腦輔助工程學系', '資料結構與演算法', 0.75),
  ('陳秋宏', '機械與電腦輔助工程學系', '機械設計與製造', 0.65),
  ('郭武彰', '機械與電腦輔助工程學系', '機械設計與製造', 0.95),
  ('郭武彰', '機械與電腦輔助工程學系', '專題與實作', 0.73),
  ('郭武彰', '機械與電腦輔助工程學系', '機器人與自動控制', 0.68),
  ('詹彥信', '機械與電腦輔助工程學系', '能源', 0.9),
  ('詹彥信', '機械與電腦輔助工程學系', '材料與化工', 0.88),
  ('詹彥信', '機械與電腦輔助工程學系', '機械設計與製造', 0.68),
  ('陳子夏', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('陳子夏', '機械與電腦輔助工程學系', '機器人與自動控制', 0.65),
  ('魏立儒', '機械與電腦輔助工程學系', '電子電路', 0.9),
  ('魏立儒', '機械與電腦輔助工程學系', '工業與產品設計', 0.85),
  ('魏立儒', '機械與電腦輔助工程學系', '機械設計與製造', 0.85),
  ('林玉堃', '機械與電腦輔助工程學系', '機器學習', 0.95),
  ('林玉堃', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('林玉堃', '機械與電腦輔助工程學系', '機器人與自動控制', 0.9),
  ('林玉堃', '機械與電腦輔助工程學系', '通訊與訊號處理', 0.9),
  ('林明賢', '機械與電腦輔助工程學系', '機械設計與製造', 0.93),
  ('林明賢', '機械與電腦輔助工程學系', '數學與數值方法', 0.85),
  ('林明賢', '機械與電腦輔助工程學系', '電子電路', 0.7)
) AS v(n, d, s, c) JOIN departments d ON d.name = v.d JOIN teachers t ON t.name = v.n AND t.department_id = d.id JOIN skills s ON s.name = v.s
ON CONFLICT DO NOTHING;
COMMIT;
