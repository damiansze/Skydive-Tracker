"""Database migration script to add new columns"""
import sqlite3
import os

def migrate_database():
    """Add new columns to existing database"""
    db_path = "skydive_tracker.db"
    
    if not os.path.exists(db_path):
        print("Database file not found. It will be created on next app start.")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check if jump_method column exists
        cursor.execute("PRAGMA table_info(jumps)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'jump_method' not in columns:
            print("Adding jump_method column to jumps table...")
            cursor.execute("ALTER TABLE jumps ADD COLUMN jump_method VARCHAR")
            conn.commit()
            print("✓ Added jump_method column")
        else:
            print("✓ jump_method column already exists")
        
        # Check if reminder_after_jumps column exists in equipment table
        cursor.execute("PRAGMA table_info(equipment)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'reminder_after_jumps' not in columns:
            print("Adding reminder_after_jumps column to equipment table...")
            cursor.execute("ALTER TABLE equipment ADD COLUMN reminder_after_jumps INTEGER")
            conn.commit()
            print("✓ Added reminder_after_jumps column")
        else:
            print("✓ reminder_after_jumps column already exists")
        
        # Check if deactivation_date column exists in equipment table
        if 'deactivation_date' not in columns:
            print("Adding deactivation_date column to equipment table...")
            cursor.execute("ALTER TABLE equipment ADD COLUMN deactivation_date DATETIME")
            conn.commit()
            print("✓ Added deactivation_date column")
        else:
            print("✓ deactivation_date column already exists")
        
        # Check if profile_picture_url column exists in profiles table
        cursor.execute("PRAGMA table_info(profiles)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'profile_picture_url' not in columns:
            print("Adding profile_picture_url column to profiles table...")
            cursor.execute("ALTER TABLE profiles ADD COLUMN profile_picture_url VARCHAR")
            conn.commit()
            print("✓ Added profile_picture_url column")
        else:
            print("✓ profile_picture_url column already exists")
        
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
                print(f"Adding {col_name} column to jumps table...")
                cursor.execute(f"ALTER TABLE jumps ADD COLUMN {col_name} {col_type}")
                conn.commit()
                print(f"✓ Added {col_name} column")
            else:
                print(f"✓ {col_name} column already exists")
        
        print("\nMigration completed successfully!")
        
    except Exception as e:
        print(f"Error during migration: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate_database()
