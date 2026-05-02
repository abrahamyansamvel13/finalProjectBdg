#!/usr/bin/env python3
"""
Database Viewer Script
Run this to inspect your database content
"""
import os
import sys
from sqlalchemy import create_engine, text

# Add app to path for imports
sys.path.insert(0, os.path.dirname(__file__))

from app.models import Base, GameStatsDB

# Use test database for now (change to your MySQL URL when set up)
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///test.db')

def view_database():
    engine = create_engine(DATABASE_URL, echo=False)
    
    # Create tables if they don't exist
    print("=== Database Viewer ===")
    print(f"Connected to: {DATABASE_URL}")
    print("Creating tables if they don't exist...")
    Base.metadata.create_all(bind=engine)
    print("✓ Tables ready\n")

    print("=== Database Viewer ===")
    print(f"Connected to: {DATABASE_URL}")
    print()

    with engine.connect() as conn:
        # Show tables
        if 'sqlite' in DATABASE_URL:
            result = conn.execute(text('SELECT name FROM sqlite_master WHERE type="table";'))
        else:
            result = conn.execute(text('SHOW TABLES;'))

        tables = result.fetchall()
        print("Tables in database:")
        for table in tables:
            print(f"  - {table[0]}")
        print()

        # Show game_stats content
        try:
            result = conn.execute(text('SELECT COUNT(*) FROM game_stats;'))
            count = result.fetchone()[0]
            print(f"Records in game_stats table: {count}")

            if count > 0:
                result = conn.execute(text('SELECT * FROM game_stats ORDER BY id;'))
                rows = result.fetchall()

                print("\nGame Stats Records:")
                print("-" * 90)
                print("ID | Game Name       | Player ID    | Score | Level | Time | Timestamp")
                print("-" * 90)

                for row in rows:
                    game_name = str(row[1])[:15].ljust(15)
                    player_id = str(row[2])[:12].ljust(12)
                    score = str(row[3]).rjust(5)
                    level = str(row[4]) if row[4] else "None"
                    play_time = str(row[5]) if row[5] else "None"
                    timestamp = str(row[6])[:19]  # Truncate timestamp
                    print(f"{row[0]:2} | {game_name} | {player_id} | {score} | {level:5} | {play_time:4} | {timestamp}")

        except Exception as e:
            print(f"Error reading game_stats table: {e}")

if __name__ == "__main__":
    view_database()