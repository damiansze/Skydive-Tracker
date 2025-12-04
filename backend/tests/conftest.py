"""Pytest configuration and fixtures"""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.database import Base, get_db
from app.main import app

# Test database (in-memory SQLite)
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database for each test"""
    Base.metadata.create_all(bind=engine)

    # Add migration columns that might be missing from the base schema
    # This simulates the migration process for tests
    from sqlalchemy import text
    try:
        # Add freefall columns to jumps table (ignore if they already exist)
        db = TestingSessionLocal()

        # Check existing columns first
        result = db.execute(text("PRAGMA table_info(jumps)"))
        existing_columns = [row[1] for row in result.fetchall()]

        freefall_cols = ['freefall_duration_seconds', 'max_vertical_velocity_ms', 'exit_time', 'deployment_time']
        weather_cols = ['weather_temperature_celsius', 'weather_wind_speed_kmh', 'weather_wind_direction_degrees',
                       'weather_wind_gusts_kmh', 'weather_code', 'weather_description', 'weather_humidity_percent',
                       'weather_pressure_hpa', 'weather_cloud_cover_percent', 'weather_visibility_km']

        for col in freefall_cols + weather_cols:
            if col not in existing_columns:
                if 'time' in col or 'date' in col:
                    col_type = 'DATETIME'
                elif 'percent' in col or 'degrees' in col or 'code' in col:
                    col_type = 'INTEGER'
                else:
                    col_type = 'REAL'
                db.execute(text(f"ALTER TABLE jumps ADD COLUMN {col} {col_type}"))

        # Equipment table columns
        result = db.execute(text("PRAGMA table_info(equipment)"))
        existing_equip_columns = [row[1] for row in result.fetchall()]
        if 'reminder_after_jumps' not in existing_equip_columns:
            db.execute(text("ALTER TABLE equipment ADD COLUMN reminder_after_jumps INTEGER"))
        if 'deactivation_date' not in existing_equip_columns:
            db.execute(text("ALTER TABLE equipment ADD COLUMN deactivation_date DATETIME"))

        # Profile table columns
        result = db.execute(text("PRAGMA table_info(profiles)"))
        existing_profile_columns = [row[1] for row in result.fetchall()]
        if 'profile_picture_url' not in existing_profile_columns:
            db.execute(text("ALTER TABLE profiles ADD COLUMN profile_picture_url VARCHAR"))

        db.commit()
        db.close()
    except Exception:
        # Columns might already exist or other errors, ignore
        pass

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db_session):
    """Create a test client"""
    app.dependency_overrides[get_db] = lambda: db_session

    from fastapi.testclient import TestClient
    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
