from database.connection import ensure_database_exists
# from data_generator.seeder import seed_data

if __name__ == "__main__":
    print("--- BẮT ĐẦU PROJECT 03 ---")
    
    # Bước 1: Tạo Schema [cite: 10]
    # init_db()
    ensure_database_exists()
    
    # Bước 2: Nạp Mock Data (Faker) [cite: 11]
    # seed_data()
    
    print("--- HOÀN TẤT ---")