"""Main FastAPI application"""
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api.v1 import jumps, equipment, profile, statistics, weather
from app.db.database import init_db
from app.core.logging_config import setup_logging, get_logger

# Setup logging
log_level = os.getenv("LOG_LEVEL", "INFO")
setup_logging(log_level)
logger = get_logger(__name__)

app = FastAPI(
    title="Skydive Tracker API",
    description="Backend API für die Fallschirmsprung-Tracking-App",
    version="1.0.0",
)

# CORS middleware for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    logger.info("Starting application", extra={"event": "app_startup"})
    try:
        init_db()
        logger.info("Database initialized successfully", extra={"event": "db_init"})
    except Exception as e:
        logger.error("Failed to initialize database", extra={"event": "db_init_error", "error": str(e)})
        raise

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down application", extra={"event": "app_shutdown"})

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(
        "Request received",
        extra={
            "event": "request",
            "method": request.method,
            "path": request.url.path,
            "client": request.client.host if request.client else None,
        }
    )
    try:
        response = await call_next(request)
        logger.info(
            "Request completed",
            extra={
                "event": "response",
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
            }
        )
        return response
    except Exception as e:
        logger.error(
            "Request failed",
            extra={
                "event": "request_error",
                "method": request.method,
                "path": request.url.path,
                "error": str(e),
            },
            exc_info=True
        )
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )

# Include routers
app.include_router(jumps.router, prefix="/api/v1/jumps", tags=["jumps"])
app.include_router(equipment.router, prefix="/api/v1/equipment", tags=["equipment"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["profile"])
app.include_router(statistics.router, prefix="/api/v1/statistics", tags=["statistics"])
app.include_router(weather.router, prefix="/api/v1/weather", tags=["weather"])

@app.get("/")
async def root():
    return {"message": "Skydive Tracker API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
