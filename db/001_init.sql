-- ============================================================================
-- AI Fitness Coach — физическая схема PostgreSQL 16
-- Файл: lr4/db/001_init.sql
-- Назначение: создание таблиц, ограничений, индексов и комментариев.
-- Соответствует SQLAlchemy-моделям app/models/models.py и расширениям ЛР4:
--   * password_reset_tokens — восстановление доступа (US-12);
--   * agent_audit_log      — аудит действий MCP-агента (US-22).
-- Порядок применения: 001_init.sql → 002_seed.sql.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Пользователи и справочники
-- ---------------------------------------------------------------------------

CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    role            VARCHAR(50)  NOT NULL DEFAULT 'user',
    password_hash   VARCHAR(255) NOT NULL,
    level           VARCHAR(50),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT ck_users_role CHECK (role IN ('user', 'admin')),
    CONSTRAINT ck_users_level CHECK (level IS NULL OR level IN ('Beginner', 'Intermediate', 'Expert'))
);

COMMENT ON TABLE users IS 'Учётные записи пользователей и администраторов';
COMMENT ON COLUMN users.password_hash IS 'bcrypt-хеш пароля; никогда не возвращается API';
COMMENT ON COLUMN users.level IS 'Уровень подготовки: Beginner / Intermediate / Expert';

CREATE TABLE equipment (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    word    VARCHAR(100) NOT NULL,
    CONSTRAINT uq_equipment_name UNIQUE (name)
);

COMMENT ON TABLE equipment IS 'Справочник доступного инвентаря для анкеты';

CREATE TABLE injuries (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    word    VARCHAR(100) NOT NULL,
    CONSTRAINT uq_injuries_name UNIQUE (name)
);

COMMENT ON TABLE injuries IS 'Медицинские ограничения и соответствующие флаги упражнений';
COMMENT ON COLUMN injuries.word IS 'Имя столбца-флага в exercises.features: Spine_Load, Knee_Load, Overhead_Mvmt';

-- ---------------------------------------------------------------------------
-- 2. Связи многие-ко-многим
-- ---------------------------------------------------------------------------

CREATE TABLE user_equipment (
    user_id       INTEGER NOT NULL,
    equipment_id  INTEGER NOT NULL,
    PRIMARY KEY (user_id, equipment_id),
    CONSTRAINT fk_user_equipment_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_equipment_equipment
        FOREIGN KEY (equipment_id) REFERENCES equipment (id) ON DELETE CASCADE
);

CREATE TABLE user_injuries (
    user_id     INTEGER NOT NULL,
    injury_id   INTEGER NOT NULL,
    PRIMARY KEY (user_id, injury_id),
    CONSTRAINT fk_user_injuries_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_injuries_injury
        FOREIGN KEY (injury_id) REFERENCES injuries (id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 3. Каталог упражнений
-- ---------------------------------------------------------------------------

CREATE TABLE exercises (
    id           SERIAL PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    "desc"       TEXT,
    body_part    VARCHAR(100) NOT NULL,
    equipment    VARCHAR(100) NOT NULL,
    level        VARCHAR(50)  NOT NULL,
    type         VARCHAR(100) NOT NULL,
    is_compound  INTEGER      NOT NULL DEFAULT 0,
    features     JSONB        NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT ck_exercises_compound CHECK (is_compound IN (0, 1)),
    CONSTRAINT ck_exercises_level CHECK (level IN ('Beginner', 'Intermediate', 'Expert'))
);

COMMENT ON TABLE exercises IS 'Каталог упражнений (~2910 записей), импортируется из Dataset_features.csv';
COMMENT ON COLUMN exercises.features IS 'One-Hot / бинарные признаки, в т.ч. Spine_Load, Knee_Load, Overhead_Mvmt';

CREATE INDEX ix_exercises_title      ON exercises (title);
CREATE INDEX ix_exercises_body_part  ON exercises (body_part);
CREATE INDEX ix_exercises_equipment  ON exercises (equipment);
CREATE INDEX ix_exercises_level      ON exercises (level);
CREATE INDEX ix_exercises_features   ON exercises USING GIN (features);

-- ---------------------------------------------------------------------------
-- 4. Планы, история и обратная связь
-- ---------------------------------------------------------------------------

CREATE TABLE saved_plans (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER NOT NULL,
    plan_data  JSONB   NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT fk_saved_plans_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

COMMENT ON TABLE saved_plans IS 'Сохранённые параметры анкеты пользователя';

CREATE INDEX ix_saved_plans_user_id ON saved_plans (user_id);

CREATE TABLE workout_history (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER NOT NULL,
    date       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    plan_data  JSONB     NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT fk_workout_history_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

COMMENT ON TABLE workout_history IS 'Журнал сгенерированных тренировок';
COMMENT ON COLUMN workout_history.plan_data IS 'Параметры запроса: duration, target_muscles, user_level_str, equipment, injuries';

CREATE INDEX ix_workout_history_user_date ON workout_history (user_id, date DESC);

CREATE TABLE workout_items (
    id                  SERIAL PRIMARY KEY,
    workout_history_id  INTEGER NOT NULL,
    exercise_id         INTEGER NOT NULL,
    "order"             INTEGER NOT NULL,
    slot_type           VARCHAR(100) NOT NULL,
    is_skipped          BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_workout_items_history
        FOREIGN KEY (workout_history_id) REFERENCES workout_history (id) ON DELETE CASCADE,
    CONSTRAINT fk_workout_items_exercise
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE,
    CONSTRAINT ck_workout_items_order CHECK ("order" > 0)
);

COMMENT ON TABLE workout_items IS 'Элементы (слоты) плана тренировки';

CREATE INDEX ix_workout_items_history ON workout_items (workout_history_id, "order");
CREATE INDEX ix_workout_items_exercise ON workout_items (exercise_id);

CREATE TABLE feedback (
    id                    SERIAL PRIMARY KEY,
    user_id               INTEGER NOT NULL,
    workout_item_id       INTEGER NOT NULL,
    timestamp             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rating                INTEGER NOT NULL,
    perceived_difficulty  VARCHAR(50),
    comment               TEXT,
    CONSTRAINT uq_feedback_workout_item UNIQUE (workout_item_id),
    CONSTRAINT fk_feedback_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_feedback_workout_item
        FOREIGN KEY (workout_item_id) REFERENCES workout_items (id) ON DELETE CASCADE,
    CONSTRAINT ck_feedback_rating CHECK (rating BETWEEN -1 AND 10)
);

COMMENT ON TABLE feedback IS 'Одна оценка на элемент плана; rating = -1 означает «заменить»';
COMMENT ON COLUMN feedback.perceived_difficulty IS 'Субъективная сложность: easy / normal / hard';

CREATE INDEX ix_feedback_user ON feedback (user_id);

-- ---------------------------------------------------------------------------
-- 5. Настройки низкого кода
-- ---------------------------------------------------------------------------

CREATE TABLE difficulty_level_words (
    id              SERIAL PRIMARY KEY,
    word            VARCHAR(100) NOT NULL,
    difficulty_mod  DOUBLE PRECISION NOT NULL,
    CONSTRAINT uq_difficulty_level_words_word UNIQUE (word),
    CONSTRAINT ck_difficulty_mod CHECK (difficulty_mod >= 0)
);

COMMENT ON TABLE difficulty_level_words IS 'Слова-модификаторы сложности упражнений';

CREATE TABLE system_settings (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    weight_body    DOUBLE PRECISION NOT NULL DEFAULT 0.6,
    weight_equip   DOUBLE PRECISION NOT NULL DEFAULT 0.3,
    weight_level   DOUBLE PRECISION NOT NULL DEFAULT 0.4,
    is_active      BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_system_settings_weights CHECK (
        weight_body >= 0 AND weight_equip >= 0 AND weight_level >= 0
    )
);

COMMENT ON TABLE system_settings IS 'Профили весов рекомендательной модели; активен ровно один';

-- Частичный уникальный индекс: в таблице может быть только одна активная строка.
CREATE UNIQUE INDEX uq_system_settings_one_active
    ON system_settings ((is_active))
    WHERE is_active;

-- ---------------------------------------------------------------------------
-- 6. Расширения ЛР4: восстановление доступа и аудит MCP
-- ---------------------------------------------------------------------------

CREATE TABLE password_reset_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL,
    token_hash  VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP NOT NULL,
    used_at     TIMESTAMP,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_password_reset_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_password_reset_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

COMMENT ON TABLE password_reset_tokens IS 'Одноразовые токены сброса пароля (TTL 30 минут)';
COMMENT ON COLUMN password_reset_tokens.token_hash IS 'Хеш токена; сам токен хранится только у пользователя';

CREATE INDEX ix_password_reset_user ON password_reset_tokens (user_id, expires_at DESC);

CREATE TABLE agent_audit_log (
    id          BIGSERIAL PRIMARY KEY,
    actor       VARCHAR(100) NOT NULL DEFAULT 'mcp-agent',
    action      VARCHAR(100) NOT NULL,
    user_id     INTEGER,
    payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    status      VARCHAR(30) NOT NULL,
    detail      TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_agent_audit_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT ck_agent_audit_status CHECK (status IN ('success', 'error', 'denied'))
);

COMMENT ON TABLE agent_audit_log IS 'Журнал действий AI-агента через MCP; секреты маскируются';
COMMENT ON COLUMN agent_audit_log.payload IS 'Параметры вызова без паролей, токенов и иных секретов';

CREATE INDEX ix_agent_audit_created ON agent_audit_log (created_at DESC);
CREATE INDEX ix_agent_audit_action  ON agent_audit_log (action, created_at DESC);
CREATE INDEX ix_agent_audit_user    ON agent_audit_log (user_id, created_at DESC);

COMMIT;
