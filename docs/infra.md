# Инфраструктура AI Coach Backend

Документ описывает контейнерное окружение, CI/CD и публикацию бэкенда.
Относится к заданию 6 лабораторной работы №4.

## Состав репозитория

| Путь | Назначение |
| ---- | ---------- |
| `app/` | FastAPI-приложение |
| `tests/` | тесты `pytest` |
| `openapi/openapi.yaml` | контракт API |
| `db/` | схема PostgreSQL и seed-данные |
| `api-tests/` | проверка контракта и smoke-тесты |
| `Dockerfile` | образ бэкенда |
| `docker-compose.yml` | локальный запуск `api` и `db` |
| `.github/workflows/ci.yml` | CI: контракт, тесты с покрытием, SonarQube, Docker |
| `.github/workflows/release.yml` | публикация образа в GHCR по тегу `v*` |
| `render.yaml` | описание сервиса для Render.com |
| `sonar-project.properties` | настройки SonarQube для project key `ai-coach-backend` |

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
python api-tests/validate_contract.py
```

## Docker

```powershell
docker compose config --quiet
docker compose up --build
```

| Сервис | Образ | Порт | Назначение |
| ------ | ----- | ---- | ---------- |
| `api` | локальная сборка `Dockerfile` | `8000` | FastAPI |
| `db` | `postgres:16-alpine` | `5432` | PostgreSQL |

`db/001_init.sql` и `db/002_seed.sql` монтируются в
`/docker-entrypoint-initdb.d` и применяются при первом старте контейнера,
поэтому схема создаётся автоматически. Данные хранятся в volume `pgdata`.

Образ собирается из `Dockerfile`, работает от непривилегированного
пользователя `appuser`, healthcheck обращается к `/health`.

## CI

`ci.yml` запускается на push в `main`, `develop`, `lab*`, `feature/**`
и на pull request в `main`/`develop`.

| Job | Что делает |
| --- | ---------- |
| `contract` | `python api-tests/validate_contract.py` |
| `test` | `pip install -r requirements.txt`, `pytest --cov=app --cov-report=xml`, артефакт `coverage-report` |
| `sonar` | `SonarSource/sonarqube-scan-action@v5`, ожидание quality gate |
| `docker` | `docker compose config`, `docker build` |

Job `sonar` зависит от `test` и получает `coverage.xml` артефактом.
Job `docker` зависит от `contract`, `test` и `sonar`: если контракт,
тесты или quality gate упали, образ не собирается.

### SonarQube

Для сканирования нужны секреты репозитория:

| Секрет | Назначение |
| ------ | ---------- |
| `SONAR_TOKEN` | токен пользователя SonarQube |
| `SONAR_HOST_URL` | адрес сервера (для SonarCloud — `https://sonarcloud.io`) |

`sonar-project.properties` уже содержит `sonar.qualitygate.wait=true`,
поэтому job завершается ошибкой при непройденном quality gate.
Ожидаемое состояние после создания репозитория и добавления секретов —
`SonarQube: Passed`.

## Публикация

`release.yml` запускается по тегу `v*`:

1. собирает образ;
2. публикует его в `ghcr.io/<owner>/<repo>` с тегами версии и `latest`.

Для публикации используется встроенный `GITHUB_TOKEN`, отдельный секрет
не нужен.

## Деплой на Render

Файл `render.yaml` описывает web-сервис:

- runtime: Docker;
- plan: free;
- healthcheck: `/health`;
- `DATABASE_URL` задаётся в панели Render (`sync: false`).

Пошаговое развертывание на бесплатных платформах описано в разделах
«Публикация» и «Деплой на Render» настоящего документа.
