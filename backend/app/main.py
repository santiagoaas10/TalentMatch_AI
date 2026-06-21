"""Application entrypoint: builds the FastAPI app via an application factory."""

from fastapi import FastAPI

from app.presentation.health import router as health_router


def create_app() -> FastAPI:
    """Build and configure the FastAPI application.

    Using a factory (instead of a module-level instance) keeps construction
    explicit and testable: routers and config are wired here, in one place.
    """
    app = FastAPI(title="TalentMatch AI", version="0.1.0")
    app.include_router(health_router)
    return app


app = create_app()
