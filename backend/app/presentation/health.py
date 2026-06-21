"""Health-check router: a liveness probe for Railway, CI and uptime monitors."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health() -> dict[str, str]:
    """Return 200 OK so external systems can confirm the API is alive."""
    return {"status": "ok"}
