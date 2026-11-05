from fastapi import APIRouter

APP_VERSION = "1.0.0"

router = APIRouter(tags=["service"])


@router.get("/health", summary="Проверка живости сервиса")
def health() -> dict[str, str]:
    """Возвращает признак того, что приложение запущено и отвечает."""
    return {"status": "ok", "version": APP_VERSION}
