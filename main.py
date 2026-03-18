from database.connection import init_db
from data_generator.seeder import seed_data

if __name__ == "__main__":
    print("--- BẮT ĐẦU PROJECT ---")
    
    # Bước 1: Tạo Schema
    init_db()
    
    # Bước 2: Nạp Mock Data (Faker)
    seed_data()
    print("--- HOÀN TẤT ---")