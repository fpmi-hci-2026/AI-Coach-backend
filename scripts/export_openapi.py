"""
Скрипт экспорта спецификации OpenAPI (Swagger) из приложения FastAPI.
Вызывается локально и в пайплайне CI/CD.
"""

from __future__ import annotations

import json
import os
import sys

# Добавляем корень проекта в путь поиска модулей
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app
from fastapi.openapi.utils import get_openapi


def export_openapi() -> None:
    output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "openapi"))
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "openapi.json")

    # Генерируем актуальную OpenAPI-схему из роутов приложения
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        openapi_version=app.openapi_version,
        description=app.description,
        routes=app.routes,
    )

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(openapi_schema, f, ensure_ascii=False, indent=2)

    print(f"Спецификация Swagger успешно экспортирована в: {output_path}")


if __name__ == "__main__":
    export_openapi()