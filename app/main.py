from fastapi import FastAPI

from app.api.health import router as health_router

app = FastAPI(
    title="AI Coach API",
    version="1.0.0",
    description=(
        "Бэкенд AI-фитнес-ассистента. "
        "Минимальный каркас лабораторной работы №4: health-check и основа "
        "для последующих модулей (пользователи, каталог, генерация планов)."
    ),
)

app.include_router(health_router)
