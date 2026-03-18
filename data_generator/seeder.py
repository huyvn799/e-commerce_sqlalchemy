from faker import Faker
import random
from datetime import timedelta
from database.models import Brand, Category, Seller, Product, Promotion, PromotionProduct
from database.connection import SessionLocal

from faker.providers import BaseProvider

# 1. Khởi tạo Faker với locale (ví dụ: Việt Nam)
fake = Faker(['vi_VN'])

# 3. Tạo Custom Provider
class BrandProvider(BaseProvider):
    def brand(self):
        # 2. Tạo danh sách thương hiệu mẫu (Dành cho Điện tử & Thời trang)
        electronics_brands = ["Samsung", "Apple", "Sony", "LG", "Asus", "Xiaomi"]
        fashion_brands = ["Nike", "Adidas", "Zara", "H&M", "Uniqlo", "Gucci"]
        return f"{random.choice(electronics_brands)} {random.choice(fashion_brands)}"

# 4. Thêm provider vào thực thể fake
fake.add_provider(BrandProvider)

def seed_data():
    session = SessionLocal()
    
    # 1. Tạo 20 Brands 48]
    print("Seeding Brands...")
    brands = []
    for _ in range(20):
        brand = Brand(
            brand_name=fake.brand(),
            country=fake.country(),
            created_at=fake.date_time_this_decade()
        )
        session.add(brand)
        brands.append(brand)
    session.commit()

    # 2. Tạo 10 Categories (Hierarchy) 53, 54]
    print("Seeding Categories...")
    categories = ['Phones & Tablets', 'Computers & Laptops', 'Digital Accessories']
    # Cấp 1 (Main)
    for i in range(3):
        cat = Category(
            category_name= categories[i],
            parent_category_id=None,
            level=1,
            created_at=fake.date_time_this_year()
        )
        session.add(cat)
    session.commit()
    
    # Cấp 2 (Sub)
    main_cat_ids = [c.category_id for c in session.query(Category.category_id).all()]
    for i in range(7):
        cat = Category(
            category_name=fake.administrative_unit(),
            parent_category_id=random.choice(main_cat_ids),
            level=2,
            created_at=fake.date_time_this_year()
        )
        session.add(cat)
        categories.append(cat)
    session.commit()

    # 3. Tạo 25 Sellers
    print("Seeding Sellers...")
    sellers = []
    for _ in range(25):
        seller = Seller(
            seller_name=fake.name(),
            join_date=fake.date_between(start_date='-3y', end_date='today'),
            seller_type=random.choice(["Official", "Marketplace"]),
            rating=round(random.uniform(3, 5), 1),
            country="Vietnam" # Fixed logic
        )
        session.add(seller)
        sellers.append(seller)
    session.commit()

    # 4. Tạo 2000 Products
    print("Seeding Products...")
    products = []
    brand_ids = [b.brand_id for b in session.query(Brand.brand_id).all()]
    category_ids = [c.category_id for c in session.query(Category.category_id).all()]
    seller_ids = [s.seller_id for s in session.query(Seller.seller_id).all()]
    
    for _ in range(2000):
        original_price = random.randrange(100000, 50000000, 100000)
        product = Product(
            product_name=fake.catch_phrase(),
            category_id=random.choice(category_ids),
            brand_id=random.choice(brand_ids),
            seller_id=random.choice(seller_ids),
            price=original_price,
            discount_price=original_price * random.uniform(0.7, 1.0),
            stock_qty=random.randint(0, 500),
            rating=round(random.uniform(3, 5), 1),
            created_at=fake.date_between(start_date='-3y', end_date='today'),
            is_active=fake.boolean()
        )
        session.add(product)
        products.append(product)
    session.commit()

    # 5. Tạo 10 Promotions
    print("Seeding Promotions...")
    promotions = []
    for _ in range(10):
        start = fake.date_between(start_date='-1y', end_date='today')
        end = start + timedelta(days=random.randint(30, 50)) # = start_date + (30-50) days
        dis_type = random.choice(['percentage', 'fixed_amount'])
        if (dis_type == 'percentage'):
            dis_val = random.randrange(10, 50, 5)
        else:
            dis_val = random.randrange(10000, 100000, 10000)
        promo = Promotion(
            promotion_name=fake.bs().title(),
            promotion_type=random.choice(['product', 'category', 'seller', 'flash_sale']),
            discount_type=dis_type,
            discount_value=dis_val,
            start_date=start,
            end_date=end
        )
        session.add(promo)
        promotions.append(promo)
    session.commit()

    # 6. Tạo 100 Promotion_Product
    print("Seeding Promotion_Products...")
    promo_ids = [p.promotion_id for p in promotions]
    product_ids = [p.product_id for p in products]
    
    for _ in range(100):
        mapping = PromotionProduct(
            promotion_id=random.choice(promo_ids),
            product_id=random.choice(product_ids),
            created_at=fake.date_time_this_year()
        )
        session.add(mapping)
    session.commit()
    
    print("Hoàn tất nạp dữ liệu!")
    session.close()
