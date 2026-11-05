-- ============================================================================
-- AI Fitness Coach — откат физической схемы
-- Файл: lr4/db/001_init.down.sql
-- ВНИМАНИЕ: удаляет все таблицы и данные. Использовать только в dev/test.
-- ============================================================================

BEGIN;

DROP TABLE IF EXISTS agent_audit_log       CASCADE;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS feedback              CASCADE;
DROP TABLE IF EXISTS workout_items         CASCADE;
DROP TABLE IF EXISTS workout_history       CASCADE;
DROP TABLE IF EXISTS saved_plans           CASCADE;
DROP TABLE IF EXISTS system_settings       CASCADE;
DROP TABLE IF EXISTS difficulty_level_words CASCADE;
DROP TABLE IF EXISTS exercises             CASCADE;
DROP TABLE IF EXISTS user_injuries         CASCADE;
DROP TABLE IF EXISTS user_equipment        CASCADE;
DROP TABLE IF EXISTS injuries              CASCADE;
DROP TABLE IF EXISTS equipment             CASCADE;
DROP TABLE IF EXISTS users                 CASCADE;

COMMIT;
