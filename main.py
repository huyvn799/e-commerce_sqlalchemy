from database.connection import init_db
from data_generator.seeder import seed_data, seed_transactions

if __name__ == "__main__":
    print("--- STARTING PROJECT ---")
    
    # Bước 1: Tạo Schema
    init_db()
    
    # Bước 2: Nạp Mock Data (Faker)
    seed_data() # Tạo mock data cho bảng brands, categories, products, sellers
    seed_transactions() # Tạo mock data cho bảng orders, order_items
    print("--- FINISHED ---")