"""Database configuration and initialization"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# SQLite database path
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./skydive_tracker.db")

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
    echo=False,  # Set to True for SQL query logging
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def init_db():
    """Initialize database tables"""
    from app.models import profile, equipment, jump  # noqa: F401
    
    Base.metadata.create_all(bind=engine)
    
    # Migrate existing database if needed
    try:
        import sqlite3
        if "sqlite" in DATABASE_URL:
            db_path = DATABASE_URL.replace("sqlite:///", "")
            if os.path.exists(db_path):
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                
                # Check and add jump_type and jump_method columns if missing
                cursor.execute("PRAGMA table_info(jumps)")
                columns = [column[1] for column in cursor.fetchall()]
                
                if 'jump_type' not in columns:
                    try:
                        cursor.execute("ALTER TABLE jumps ADD COLUMN jump_type VARCHAR")
                        conn.commit()
                    except sqlite3.OperationalError as e:
                        if "duplicate column" not in str(e).lower():
                            raise
                
                if 'jump_method' not in columns:
                    try:
                        cursor.execute("ALTER TABLE jumps ADD COLUMN jump_method VARCHAR")
                        conn.commit()
                    except sqlite3.OperationalError as e:
                        if "duplicate column" not in str(e).lower():
                            raise
                
                # Check and add reminder_after_jumps column if missing
                cursor.execute("PRAGMA table_info(equipment)")
                columns = [column[1] for column in cursor.fetchall()]
                if 'reminder_after_jumps' not in columns:
                    try:
                        cursor.execute("ALTER TABLE equipment ADD COLUMN reminder_after_jumps INTEGER")
                        conn.commit()
                    except sqlite3.OperationalError as e:
                        if "duplicate column" not in str(e).lower():
                            raise
                
                # Check and add is_active column if missing
                if 'is_active' not in columns:
                    try:
                        cursor.execute("ALTER TABLE equipment ADD COLUMN is_active INTEGER DEFAULT 1")
                        conn.commit()
                    except sqlite3.OperationalError as e:
                        if "duplicate column" not in str(e).lower():
                            raise
                
                # Check and add deactivation_date column if missing
                if 'deactivation_date' not in columns:
                    try:
                        cursor.execute("ALTER TABLE equipment ADD COLUMN deactivation_date DATETIME")
                        conn.commit()
                    except sqlite3.OperationalError as e:
                        if "duplicate column" not in str(e).lower():
                            raise
                
                # Check and add profile_picture_url column if missing
                cursor.execute("PRAGMA table_info(profiles)")
                columns = [column[1] for column in cursor.fetchall()]
                if 'profile_picture_url' not in columns:
                    cursor.execute("ALTER TABLE profiles ADD COLUMN profile_picture_url VARCHAR")
                    conn.commit()
                
                # Check and add freefall_stats columns to jumps table
                cursor.execute("PRAGMA table_info(jumps)")
                columns = [column[1] for column in cursor.fetchall()]
                
                freefall_columns = {
                    'freefall_duration_seconds': 'REAL',
                    'max_vertical_velocity_ms': 'REAL',
                    'exit_time': 'DATETIME',
                    'deployment_time': 'DATETIME',
                }
                
                for col_name, col_type in freefall_columns.items():
                    if col_name not in columns:
                        try:
                            cursor.execute(f"ALTER TABLE jumps ADD COLUMN {col_name} {col_type}")
                            conn.commit()
                        except sqlite3.OperationalError as e:
                            if "duplicate column" not in str(e).lower():
                                raise
                
                conn.close()
    except Exception as e:
        # Migration errors are not critical - log but don't fail
        import logging
        logging.warning(f"Database migration warning: {e}")

def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
