-- ============================================================================
-- AI Fitness Coach — справочные данные
-- Файл: lr4/db/002_seed.sql
-- Применять после 001_init.sql.
-- Каталог упражнений (~2910 записей) загружается отдельно:
--   python scripts/import_csv.py  (источник: data/Dataset_features.csv)
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Инвентарь
-- ---------------------------------------------------------------------------
INSERT INTO equipment (name, word) VALUES
    ('Body Only',           'Body Only'),
    ('Dumbbell',            'Dumbbell'),
    ('Barbell',             'Barbell'),
    ('EZ Curl Bar',         'EZ Curl Bar'),
    ('Cable',               'Cable'),
    ('Machine',             'Machine'),
    ('Kettlebells',         'Kettlebells'),
    ('Bands',               'Bands'),
    ('Medicine Ball',       'Medicine Ball'),
    ('Exercise Ball',       'Exercise Ball'),
    ('Foam Roll',           'Foam Roll'),
    ('None',                'None')
ON CONFLICT (name) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Медицинские ограничения (флаги должны совпадать с features упражнений)
-- ---------------------------------------------------------------------------
INSERT INTO injuries (name, word) VALUES
    ('Knee (Колени)',        'Knee_Load'),
    ('Spine (Позвоночник)',  'Spine_Load'),
    ('Shoulder (Плечи)',     'Overhead_Mvmt')
ON CONFLICT (name) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Слова-модификаторы сложности
-- ---------------------------------------------------------------------------
INSERT INTO difficulty_level_words (word, difficulty_mod) VALUES
    ('one arm',          1.0),
    ('one leg',          1.0),
    ('weighted',         0.5),
    ('decline',          1.0),
    ('incline',          0.3),
    ('side to side',     0.6),
    ('alternating',      0.4),
    ('plyo',             1.0),
    ('explosive',        1.0),
    ('clapping',         1.5),
    ('behind the neck',  0.8),
    ('wide grip',        0.2)
ON CONFLICT (word) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4. Профиль весов по умолчанию (ровно один активный)
-- ---------------------------------------------------------------------------
INSERT INTO system_settings (name, weight_body, weight_equip, weight_level, is_active)
SELECT 'Стандартные веса', 0.6, 0.3, 0.4, TRUE
WHERE NOT EXISTS (SELECT 1 FROM system_settings);

COMMIT;
