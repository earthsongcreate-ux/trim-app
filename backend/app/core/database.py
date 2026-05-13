from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.engine import URL
import os
from dotenv import load_dotenv

load_dotenv()

POSTGRES_SERVER = os.getenv("POSTGRES_SERVER", "localhost")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_USER = os.getenv("POSTGRES_USER", "trim_user")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "trim_password")
POSTGRES_DB = os.getenv("POSTGRES_DB", "trim_db")

DATABASE_URL = os.getenv("DATABASE_URL", "").strip()

if DATABASE_URL and "REPLACE" not in DATABASE_URL:
    engine_url = DATABASE_URL
else:
    query = {}
    if POSTGRES_SERVER not in ("localhost", "127.0.0.1"):
        query["sslmode"] = "require"

    engine_url = URL.create(
        "postgresql+psycopg2",
        username=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
        host=POSTGRES_SERVER,
        port=int(POSTGRES_PORT),
        database=POSTGRES_DB,
        query=query,
    )

engine = create_engine(engine_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
