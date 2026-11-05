# AI Coach Backend

Бэкенд AI-фитнес-ассистента. На этапе ЛР4 это минимальный каркас:
FastAPI-приложение с одним эндпоинтом `/health`, тестом, Docker-образом
и CI. Бизнес-логика (пользователи, каталог, генерация планов) добавляется
по плану работ.

## Структура

| Путь | Назначение |
| ---- | ---------- |
| `app/main.py` | создание FastAPI-приложения |
| `app/api/health.py` | эндпоинт `GET /health` |
| `tests/` | тесты `pytest` |
| `openapi/openapi.yaml` | контракт API (задания 3–4) |
| `db/` | физическая схема PostgreSQL и seed-данные |
| `api-tests/` | валидация контракта и smoke-тесты |
| `scripts/export_openapi.py` | экспорт схемы FastAPI |
| `docs/infra.md` | инфраструктура, Docker, CI/CD |
| `.github/workflows/` | CI и публикация образа |

## Локальный запуск

```powershell
cd "D:\Code\BSU\P4MI\Lab1\AI-Coach-backend"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Проверка:

```powershell
curl.exe http://127.0.0.1:8000/health
python -m pytest -q
```

## Docker

```powershell
docker compose up --build
```

Compose поднимает `api` и `db` (PostgreSQL 16). SQL-файлы из `db/`
применяются автоматически при первом старте контейнера.

## CI

`ci.yml` выполняет три проверки:

1. `contract` — валидация `openapi/openapi.yaml`;
2. `test` — `pytest`;
3. `docker` — `docker compose config` и сборка образа.

Публикация образа в GHCR выполняется по тегу `v*` в `release.yml`.

## Документация

- инфраструктура: [`docs/infra.md`](docs/infra.md);
- отчёт по ЛР4: `../AI-Coach.wiki/Лабораторная-4.md`;
- план работ по бэкенду: `../AI-Coach.wiki/План работ по бэкенду (ЛР4).md`.
