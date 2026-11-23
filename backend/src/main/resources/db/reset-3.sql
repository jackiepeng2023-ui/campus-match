-- 3.x 遷移新增的資料表與遷移紀錄。重建（Demo 模式或首次初始化）時先刪掉，schema.sql 才能回到 2.0 基準版，
-- 之後再由遷移腳本重新建立。新增資料表的遷移腳本要同步把資料表加到這裡。
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversation_members CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS flyway_schema_history CASCADE;
