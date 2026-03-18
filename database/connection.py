import os
import psycopg2
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
# from .models import Base

# Tải các biến môi trường từ file .env
load_dotenv()

# Lấy thông tin từ biến môi trường, có kèm giá trị mặc định nếu không tìm thấy
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "ecommerce_db")

# Tạo URL kết nối cho SQLAlchemy
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def ensure_database_exists():
    """Kiểm tra và tạo DB vật lý nếu chưa có"""
    try:
        # Kết nối tới db 'postgres' để quản trị
        conn = psycopg2.connect(
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            dbname="postgres"
        )
        conn.autocommit = True
        cur = conn.cursor()

        cur.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
        if not cur.fetchone():
            print(f"Đang tạo database: {DB_NAME}...")
            cur.execute(f"CREATE DATABASE {DB_NAME}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Lỗi kết nối database: {e}")
        raise

# Khởi tạo Engine
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_db():
    ensure_database_exists()
    Base.metadata.create_all(bind=engine)
    print("Schema initialized successfully!")