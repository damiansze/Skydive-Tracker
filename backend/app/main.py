"""Main FastAPI application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import jumps, equipment, profile, statistics
from app.db.database import init_db

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
    init_db()

# Include routers
app.include_router(jumps.router, prefix="/api/v1/jumps", tags=["jumps"])
app.include_router(equipment.router, prefix="/api/v1/equipment", tags=["equipment"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["profile"])
app.include_router(statistics.router, prefix="/api/v1/statistics", tags=["statistics"])

@app.get("/")
async def root():
    return {"message": "Skydive Tracker API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
