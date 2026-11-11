-- 課綱節錄：由 tools/ref_napai.py 從 tools/data/syllabus_samples.json 產生（來源：逢甲大學課程檢索系統＋教學大綱查詢，公開頁面）
BEGIN;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('資料結構', NULL, 115, 1, '【課程描述】本課程的目標在於讓學生經由實習課程的進行，學習程式設計的技巧與訓練程式設計的能力。本課程主要訓練學生(1)能夠以高階的抽象型式適當地來定義需要的資料結構及演算法，(2)能夠設計各種資料結構實作方法，(3)能夠正確利用各種資料結構於各種程式的練習，以及(4)具有分析各種資料結構運算時間複雜度的能力。
【課程目標】學習並理解各種資料結構的知識。；應用各種資料結構的能力。；增強程式設計能力。
【核心能力】運用數學、科學及工程知識的能力。；使用技能、技術與現代工程工具的能力。；設計、執行實驗、分析與詮釋數據的能力。
【授課進度】Basic Concepts；Arrays；Stacks and Queues；Linked Lists (1)；期中考；Linked Lists (2)；tree；Graph；期末考', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11511367&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('資料結構與演算法', NULL, 115, 1, '【課程描述】本課程將學習資料結構與演算法的理論與應用，藉由探討資料的不同表示方式與優缺點，學習如何設計好的資料結構及演算法，進而設計出高效率的程式，以提升程式設計和解決問題的能力。課程內容包含簡介資料結構的種類與功能特色、介紹資料結構的基本原理與應用、及介紹演算法原理說明與實際應用。
【課程目標】資料結構說明與講解其應用；介紹簡易演算法；運用合適的演算法設計AI的應用
【核心能力】運用人工智慧技術與工具的能力；設計與執行實驗，並分析與詮釋AI跨域應用
【學習工具】VS Code 程式編輯器、Python 3.11 Python程式編譯與執行、miniconda Python套件管理程式
【授課進度】課程說明、 資料結構與演算法導論 Introduction to Algorithm；演算法分析與複雜度 Analyzing algorithms and Complexity Notation；連結串列、單向環狀連結串列、雙向連結串列、雙向環狀連結串列 Linked List、Circular Singly Linked List、Doubly Linked List、Circular Doubly Linked List；堆疊與佇列 Stack and Queue；樹／二元樹 Tree / Binary Tree；二元搜尋樹 Binary Search Tree；AVL 樹 AVL Tree 紅黑樹 Red-Black Tree；期中考 Mid-term exam；字典樹與雜湊技術 Trie and Hashing；排序演算法 Sort Algorithms；搜尋演算法 Searching Algorithms；Graph Algorithms 圖演算法；貪婪演算法 Greedy Algorithms；分治演算法 Divide and Conquer Algorithms；動態規劃 Dynamic Programming；期末考 Final exam；引導式自主學習；引導式自主學習', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510888&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('資料庫系統', NULL, 114, 2, '【課程描述】瞭解資料庫的基本原理和結構。課程內容包括資料庫系統概念和架構，實體關係模型，檔案與索引結構，關連式模型，SQL，從ER轉換成關連式綱目，以及正規化。
【課程目標】瞭解資料庫管理系統之功能；瞭解資料庫塑模和關連式資料庫之基礎與運用。；說明資料庫正規化的目的及方法；運用SQL於查詢資料庫之資料
【核心能力】運用數學、科學及工程知識的能力。；設計工程系統、組件或製程所需要的能力。；使用技能、技術與現代工程工具的能力。
【學習工具】PHP, MySQL, MySQL Workbench 學生需在課堂中透過 MySQL Workbench 進行即時的 SQL 語法撰寫與資料庫連線操作，透過執行結果修正邏輯。
【授課進度】Syllabus & Database System Concepts and Architectures；Data Modeling Using the Entity-Relationship Model (ER Model)；Normalization for Relational Databases；Basic Structure Query Language (I) (II)；Advanced Structure Query Language (I) (II)；Mid exam；Indexing: B+ Tree；Transaction Management and Database Security；NoSQL Systems；Web Application Development with Database Integration；Final project；Final exam', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11421264&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('計算機概論', NULL, 115, 1, '【課程描述】本課程在教授學生網路基本知識與基本網路架設、網頁設計與網路建置、網路應用與電子商務、以及網路的陷阱與省思。
【課程目標】認識資訊網路與應用；網路工具操作；瞭解網路安全與資訊倫理重要性
【核心能力】學生具備跨領域及問題解決能力
【學習工具】Orange Date Mining 跨平台 open source 免費軟體
https://orangedatamining.com/download/
官方Youtube教學頻道
https://www.youtube.com/channel/UClKKWBe2SCAEyv7ZNGhIe4g
【授課進度】9/11 課程導論 / 資訊科技與數位轉型；9/18 計算機系統；9/25 中秋節 資安、隱私與倫理；10/2 網路、網際網路與雲端運算；10/9 國慶日補假 人工智慧導論；10/16、10/23 大數據分析與機器學習在金融的應用；10/30 期中考；11/6 深度學習與類神經網路；11/13 AI 在金融科技（FinTech）中的應用；11/20 聊天機器人與智慧客服；11/27 區塊鏈與金融科技；12/04、12/11 常見 AI 大模型概覽；12/18 AI 挑戰、資安與倫理考量 AI 在金融領域的未來挑戰與機會；12/25 行憲紀念日 - 新興技術與創新應用；1/1 彈性自主學習週 配合學校推動「16+2週彈性學習制度」，本系第17-18週擬提供系上同學多元自主學習活動之規劃方向，同學們可依建議自行規劃17-18週至少2項學習活動，並上傳「學生學習規劃書及心得」(參考格式請見ilearn上的附件)至課程之iLearn平台提交。；1/8 彈性自主學習週 配合學校推動「16+2週彈性學習制度」，本系第17-18週擬提供系上同學多元自主學習活動之規劃方向，同學們可依建議自行規劃17-18週至少2項學習活動，並上傳「學生學習規劃書及心得」(參考格式請見ilearn上的附件)至課程之iLearn平台提交。', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510306&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('作業系統(一)', NULL, 115, 1, '【課程描述】本課程旨在介紹電腦作業系統的內部組成與運作原理，也就是電腦系統內部管理的相關知識。課程內容包括作業系統的基本介紹與回顧，與硬體相關的介面需求，然後對於作業系統的各項組成元件模組，如行程管理，CPU排班，行程同步與死結，主記憶體的管理，虛擬記憶體機制的結構與運作，分別詳細解說。
本課程要求學生結合課程所學，前往校外社區、中小學、公益機構等單位，進行12小時的「服務學習」。
【課程目標】理解作業系統整體運作原理與內部結構；理解作業系統各項資源之管理策略與機制
【核心能力】運用數學、科學及工程知識的能力。
【學習工具】自由免費軟體 For OS program assignments
【授課進度】課程規定 作業系統介紹 Overview；作業系統結構 Operating System Structure；行程觀念 Process Concept；行程管理-行程間通訊 Process Management - Interprocess Communication；行程管理-多執行緒 Process Management - Multithread；行程管理-並行性 Process Management - Concurrency；行程管理-CPU排班 Process Management - CPU Scheduling；期中考 Mid Term Exam；行程管理-多處理器排班 Process Management - Multi-Processor Scheduling；行程管理-同步工具 Process Management - Synchronization Tool；行程管理-號誌 Process Management - Semaphores；行程管理-死結 Process Management - Deadlocks；行程管理-預防死結 Process Management - Deadlocks Prevention；記憶體管理-主記憶體 Memory Management-Main Memory；記憶體管理-分頁 Memory Management-Paging；期末考 Final exams；彈性學習週；彈性學習週', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11511393&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('機器學習', NULL, 115, 1, '【課程描述】本課程將介紹基礎機器學習與軟計算的理論與實務。學習機包含類神經網路、廣義徑向幅基函數網路、模糊神經網路及支撐向量機。進化演算則包含基因演算法、粒子群聚最佳化演算法及布穀鳥搜尋法。教學目標為建立學生在機器學習與軟計算必要的根基，以便將所學之技術應用在他/她們自己的問題上。
【課程目標】明白與理解機器學習的各種理論基礎；執行實驗以及分析與詮釋數據的能力
【核心能力】具備與運用數學、科學及工程領域專業知識的能力。；設計、執行實驗與工程實務，以及分析與詮釋數據的能力。', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11513634&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('統計學(一)', NULL, 115, 1, '【課程描述】統計學(一)為統計入門課程，從機率概念由淺入深導引學生進入基本統計觀念，瞭解抽樣分配與估計的演算與運用。主題包括資料整理、機率概念、常用之機率分配、抽樣分配、點估計與區間估計。
【課程目標】知道何謂統計學之應用與敘述統計學；知道機率分配函數及其用法；知道抽樣、抽樣分配及點估計
【核心能力】學生具備跨領域及問題解決能力
【授課進度】Data and Statistics；Descriptive Statistics:Tabular and Graphical Presentations；Descriptive Statistics: Numerical Measures；Introduction to Probability；Discrete Probability Distribution；Midterm exam；Continuous Probability Distribution；Sampling and Sampling Distribution；Interval Estimation；Final exam', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510123&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('行銷管理', NULL, 115, 1, '【課程描述】從策略性的觀點，研討行銷管理的程序，包括分析行銷環境、策略性行銷決策、戰術性行銷決策，以及執行與控制等，期使能結合理論與實務，提昇行銷管理素養，並培養分析判斷之能力。
【課程目標】應用行銷口與溝通技巧
【核心能力】學生具備溝通表達能力
【授課進度】Summver vacation；Course overview and policies Ch 1 Marketing: Creating Customer Value and Engagement；Ch 1 Marketing: Creating Customer Value and Engagement；Day off: Teacher''s Day；Ch 2 Company and Marketing Strategy: Partnering to Build Customer Engagement, Value, and Relationships；Ch 3 Analyzing the Marketing Environment；Ch 4 Managing Marketing Information to Gain Customer Insights Ch 5 Understanding Consumer and Business Buyer Behavior；Memorial Day (Observed)；Midterm exams；Ch 6 Customer Value-Driven Marketing Strategy: Creating Value for Target Customers；Ch 7 Product, Services, and Brands: Building Customer Value；Ch 8 Developing New Products and Managing the Product Life Cycle；Ch 9 Pricing: Understanding and Capturing Customer Value；Ch10 Marketing Channels: Delivering Customer Value Ch11 Retailing and Wholesaling；Ch12 Engaging Customers and Communicating Customer Value: Advertising and Public Relations；Ch12 Engaging Customers and Communicating Customer Value: Advertising and Public Relations；Ch13 Personal Selling and Sales Promotion Final-term exams；跨域學習周：行銷相關主題影片', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510219&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('會計學(一)', NULL, 115, 1, '【課程描述】本課程介紹基本會計學原則及觀念，主要包括：會計恆等式、交易分析、會計分錄、調整分錄、結帳分錄、會計循環、財務報表、買賣業會計、存貨、現金與內部控制。
【課程目標】能知道會計學(一)涵蓋的主要內容及現代企業的財務報表和其限制。；能理解可應用會計學原理的情況。
【核心能力】學生具備商管專業的思辨學習能力
【學習工具】Kahoo
智慧TA學習輔助系統
【授課進度】Ch.1 Accounting in Action；Ch.2 The Recording Process；Ch.2 The Recording Process Ch.3 Adjusting the Accounts；Ch.3 Adjusting the Accounts；Mid Exam.；Ch.4 Completing the accounting cycle；Ch.5 Accounting for Merchandising operations；Ch.6 Accounting for Inventories；Ch.7 Internal control and cash；Final Exam；自主學習：手寫習題筆記', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510091&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('微積分(一)', NULL, 115, 1, '【課程描述】內容包含函數極限，導數，導函數，微分公式，鏈鎖律，隱微分，高階導數，線性近似與微分量，極大和極小值，導數與函數圖形之關係，無窮極限，水平漸近線，反導數，定積分，微積分基本定理，不定積分，代換法，曲線所圍之區域面積，自然對數函數，自然指數函數，一般對數與指數函數，反三角函數，並探討相關應用。
【課程目標】理解單變數實數值函數之極限、連續、導數及積分定義，並建立相關定理，從中訓練學生邏輯分析能力。；理解基本函數極限、連續、導數及積分之運算規則，並使學生熟練運算技巧。；應用微積分理論及運算技巧處理相關幾何問題及極大極小值問題等，並為經濟學與物理學等跨領域學習作準備。
【核心能力】學生具備商管專業的思辨學習能力；學生具備溝通技巧；學生具備跨領域及問題解決能力
【授課進度】Exponential Functions; Logarithmic Functions; Introduction to Limits；Introduction to Limits; Infinite Limits and Limits at Infinity；The Derivative；Basic Differentiation Properties; Differentials；Differentials; Derivatives of Exponential and Logarithmic Functions；Derivatives of Exponential and Logarithmic Functions; Derivatives of Products and Quotients; Derivatives of Trigonometric Functions；The Chain Rule；10/28(三)統籌科目期中會考；Implicit Differentiation；First Derivative and Graphs；Second Derivative and Graphs；Absolute Maxima and Minima；Antiderivatives and Indefinite Integrals; Integration by Substitution；Integration by Substitution; The Definite Integral；The Fundamental Theorem of Calculus；Area Between Curves；12/28(一); 12/29(二)統籌科目期末會考；12/28(一)~01/08(五)為彈性(自主)學習週', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510096&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('工程圖學(一)', NULL, 115, 1, '【課程描述】工程圖說是所有工程建設之基礎，工程設計人員乃是藉由工程圖說傳達其設計概念與細節，施工人員則是依據工程圖說進行施工。因此，工程圖說的識讀與繪製乃是所有工程人員必備的一項基本技能。本課程內容分為上下兩學期，目的在使學生瞭解土木建築工程的製圖原理及識讀工程圖的內容，同時熟悉電腦繪圖軟體與繪圖技術，以進行工程圖的繪製。上學期講授2D工程圖識圖時，搭配3D建模軟體Sketchup；講授工程圖繪製時，則使用AutoCAD；下學期主要教授3D建模原理與技術，使用Revit。
【課程目標】瞭解土木建築工程的製圖原理及識讀工程圖的內容；熟悉電腦繪圖軟體與繪圖技術
【核心能力】應用管理技術、測量、量測、資訊處理等工具，分析方法與軟體，及土木工程材料的能力。
【學習工具】Autodesk Revit Autodesk Revit
【授課進度】放樣與開挖；筏式基礎；1F結構體(梁柱版)；1F結構體(牆)；1F附屬物(樓梯、門窗)；1F附屬物(雨遮、冷氣口)；2-5F結構體；2-5F附屬物(樓梯)；2-5F附屬物(電梯開口)；屋頂層(樓板、女兒牆)；屋頂層(豎井、管道間)；屋突壹層；屋突貳層；調整放假一天；屋突參層；出圖；彩現與動畫；期末專案', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510978&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('管理學', NULL, 115, 1, '【課程描述】管理學是一門兼具科學與藝術的統整性學科。其目的在培養學生成為具備國際觀、前瞻性和競爭力的經理人。課程重視管理知識的傳授和管理能力的培養。課程實施側重於實務導向。從核心概念的建立，逐步導入國內外企業管理實務，強調整合性思考和實務應用。
【課程目標】能夠理解何謂管理學、企業的外在環境因素、管理程序。；能夠知道外在環境因素對企業的影響和衝擊;瞭解管理功能的內涵和彼此之相關性。；能夠理解並比較各種管理理論之特性;掌握新的管理發展趨勢並應用在企業實務。；能夠理解企業如何將企業倫理和社會責任以及環保等重要議題，融入經營管理決策，強化企業永續經營理念。
【核心能力】學生具備商管專業的思辨學習能力；學生具備專業倫理觀念與態度
【學習工具】Canva、無
【授課進度】課程簡介；企業、管理與管理者；管理理論；企業倫理與社會責任(1)；企業倫理與社會責任(2)；環境分析；決策、規劃與策略 (1)；決策、規劃與策略 (2)；期中考試週；CHECK POINT；激勵與領導 溝通與控制；專題演講：題目暫定，講者邀約中；個案討論；期末報告(一)；期末報告(二)；期末回饋與總結；1.輔導學生參與全國性、校級或院級之競賽。 2.舉辦定錨課程競賽、深碗專題競賽、跨學期畢業專題競賽..等。 3.輔導進行學生線上自主學習。 4.多元學習資源：包含專業實習廠商諮詢及輔導、企業參訪、課程演講。；1.輔導學生參與全國性、校級或院級之競賽。 2.舉辦定錨課程競賽、深碗專題競賽、跨學期畢業專題競賽..等。 3.輔導進行學生線上自主學習。 4.多元學習資源：包含專業實習廠商諮詢及輔導、企業參訪、課程演講。', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510143&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('經濟學(一)', NULL, 115, 1, '【課程描述】讓學生從經濟學的課程中瞭解經濟體系中的消費者、生產者、及政府單位如何在有限制的條件下做選擇。將理論的邏輯推理運用在日常生活當中。
【課程目標】1.理解基本的經濟問題，供需原理，價格機能的運作及相關實例之應用。；2. 理解市場失靈之原因及其對策。；3. 理解廠商的生產及成本理論。；4.理解不同的市場結構，及廠商的訂價行為。
【核心能力】學生具備商管專業的思辨學習能力
【學習工具】紙本教科書
電子教科書
平板電腦
其他筆記用品 1. 為提升學習效率，同學可依個人習慣，自由選擇並使用合適的學習輔助工具（如：平板電腦、電子書、紙本書、筆記本等）。
2. 因版權及授權問題，本課程將不提供與課本有關之紙本及數位教材，同學若有需求可自行向書商或學長姐洽詢新書或徵求二手教材。
【授課進度】Chap. 2 Thinking Like an Economist (pp.19-33) Chap. 3 Interdependence and the Gains from Trade (pp.45-55)；Chap. 4 The Market Forces of Supply and Demand (pp.61-83)；Chap. 5 Elasticity and Its Application (pp.87-106)；Chap. 6 Supply, Demand, and Government Policies (pp.109-126)；Chap. 7 Consumers, Producers, and the Efficiency of Markets (pp.129-145)；Chap. 10 Externalities (pp.185-203)；Chap. 14 The Costs of Production (pp.261-276)；Midterm Exam (期中考試)；Chap. 14 The Costs of Production (pp.261-276) Chap. 15 Firms in Competition Markets (pp.281-300)；Chap. 15 Firms in Competition Markets (pp.281-300)；Chap. 16 Monopoly (pp.305-328)；Chap. 16 Monopoly (pp.305-328) Chap. 17 Monopolistic Competition (pp.335-343)；Chap. 17 Monopolistic Competition (pp.335-343)；Chap. 17 Monopolistic Competition (pp.335-343) Chap. 18 Oligopoly (pp.353-365)；Chap. 18 Oligopoly (pp.353-365)；Review and Practice；Final Exam (經濟學統籌期末會考)；彈性學習周次', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11510093&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('英文(一)', NULL, 115, 1, '【課程描述】這門課的主要重點是藉由課堂上不同的活動，來增進學生的英文單字量、文法分析與閱讀理解。過程當中，也會帶領同學們學習不同的閱讀技巧，來強化同學們的閱讀能力。除了單字、文法以及閱讀能力的強化外，亦將透過特定主題，來選取不同背景之文章來進行授課，以期厚實學生的文化底蘊。
【課程目標】具備英文聽、說、讀、寫的應用能力。；具備職涯發展的英文知識。
【核心能力】具有英/外語聽、說、讀、寫的溝通能力
【授課進度】Course Description；Intro；Unit 1；Unit 1；Unit 2；Unit 2；Unit 2；Midterm Exam；Unit 3；Unit 3；Unit 3；Unit 4；Unit 4；Unit 4；Review；Final Exam；No Class (統籌考試)；Self-reflections', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11512010&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('人工智慧導論', NULL, 115, 1, '【課程描述】本課程的目標在於讓學生能對人工智慧與深度學習有清楚的認識，了解各類型系統的架構與運作原理，也對各種應用與實踐進行介紹。
【課程目標】能了解人工智慧模式的運作原理；能對人工智慧的應用與實踐有所認識
【核心能力】適當之應用數學、科學與通訊工程知識之能力；在工程實務中，有使用適當的技能、技術及現代工具之能力
【授課進度】課程介紹 人工智慧重要發展與章節概覽；深度學習的產業、專題、研究應用 線上授課，youtube 連結；智慧代理人；搜尋與問題求解；機器學習；期中考；知識與推理；不確定知識與推理；論文閱讀；期末考；論文報告', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11512180&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ('軟體工程開發實務', NULL, 115, 1, '【課程描述】介紹軟體工程基本的原則與觀念。學生修習此課後可以學習到軟體工程紀律、專案管理、需求、設計、測試、版本管理及軟體維護等基本觀念。學生可以透過操作軟體工程工具的方式學習這些概念。
【課程目標】了解軟體工程紀律於軟體開發的重要性；了解開發軟體系統所需的工程原則與方法；學習使用各種軟體工程輔助工具
【核心能力】認知專業與道德責任的能力。；運用數學、科學及工程知識的能力。；使用技能、技術與現代工程工具的能力。
【授課進度】課程簡介 - 做一個AI 時代的軟體工程師！；軟體發展生命週期與專案管理；傳統與敏捷軟體開發方法論；大型軟體開發需求蒐集與管理議題；物件導向軟體開發方法論；軟體開發實務 I - 物件導向分析設計；軟體架構設計與樣式應用；期中考試；學期專題進度報告；大型軟體開發程式碼建構議題；物件導向軟體系統開發；物件導向原則與設計重構；大型軟體測試導入與保固維護；軟體工程的進化與發展；期末考試；學期專題期末發表', 'https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=11511407&lang=cht') ON CONFLICT (course_name, department) DO NOTHING;
COMMIT;
