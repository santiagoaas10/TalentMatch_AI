"""Use case: GET /health is a liveness probe that returns 200 + {"status": "ok"}.

Written before the implementation (TDD — RED phase).
"""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
