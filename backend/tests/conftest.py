"""Pytest configuration and fixtures"""
import pytest
import tempfile
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.database import Base, get_db
from app.main import app

# Test database (file-based SQLite for FastAPI compatibility)
_temp_db_fd, _temp_db_path = tempfile.mkstemp(suffix='.db')
os.close(_temp_db_fd)  # Close the file descriptor, we just need the path
SQLALCHEMY_DATABASE_URL = f"sqlite:///{_temp_db_path}"

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="session", autouse=True)
def cleanup_test_db():
    """Clean up the test database file after all tests"""
    yield
    # Clean up the temporary database file
    try:
        os.unlink(_temp_db_path)
    except FileNotFoundError:
        pass

@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database for each test"""
    # Import models to ensure they're registered with SQLAlchemy Base
    from app.models import profile, equipment, jump  # noqa: F401

    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        # Clean up the database content between tests
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db_session):
    """Create a test client"""
    import os

    # Set the database URL environment variable for the app
    original_db_url = os.environ.get("DATABASE_URL")
    os.environ["DATABASE_URL"] = SQLALCHEMY_DATABASE_URL

    # Override the database dependency to use our test session
    app.dependency_overrides[get_db] = lambda: db_session

    from fastapi.testclient import TestClient
    with TestClient(app) as test_client:
        yield test_client

    # Restore original environment
    if original_db_url is not None:
        os.environ["DATABASE_URL"] = original_db_url
    else:
        os.environ.pop("DATABASE_URL", None)

    app.dependency_overrides.clear()
