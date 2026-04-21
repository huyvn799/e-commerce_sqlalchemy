from sqlalchemy import Column, ForeignKey
from sqlalchemy.sql.sqltypes import (
    Integer,
    BigInteger,
    String,
    Numeric,
    Boolean,
    DateTime,
    Date,
    SmallInteger,
    Float
)
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime, UTC

Base = declarative_base()

class Brand(Base):
    __tablename__ = 'brands'
    brand_id = Column(Integer, primary_key=True) # SERIAL PRIMARY KEY
    brand_name = Column(String(100), nullable=False)
    country = Column(String(50))
    created_at = Column(DateTime, default=datetime.now(UTC))

class Category(Base):
    __tablename__ = 'categories'
    category_id = Column(Integer, primary_key=True)
    category_name = Column(String(100), nullable=False)
    parent_category_id = Column(Integer, ForeignKey('categories.category_id'), nullable=True)
    level = Column(SmallInteger, nullable=False) # 1=main, 2=sub
    created_at = Column(DateTime, default=datetime.now(UTC))

class Seller(Base):
    __tablename__ = 'sellers'
    seller_id = Column(Integer, primary_key=True)
    seller_name = Column(String(150), nullable=False)
    join_date = Column(Date)
    seller_type = Column(String(50)) # 'Official', 'Marketplace'
    rating = Column(Numeric(2, 1)) # DECIMAL(2,1)
    country = Column(String(50), default="Vietnam")

class Product(Base):
    __tablename__ = 'products'
    product_id = Column(Integer, primary_key=True)
    product_name = Column(String(200), nullable=False)
    category_id = Column(Integer, ForeignKey('categories.category_id'))
    brand_id = Column(Integer, ForeignKey('brands.brand_id'))
    seller_id = Column(Integer, ForeignKey('sellers.seller_id'))
    price = Column(Numeric(12, 2), nullable=False)
    discount_price = Column(Numeric(12, 2))
    stock_qty = Column(Integer, default=0)
    rating = Column(Float)
    created_at = Column(DateTime, default=datetime.now(UTC))
    is_active = Column(Boolean, default=True)

class Order(Base):
    __tablename__ = 'orders'
    order_id = Column(Integer, primary_key=True)
    order_date = Column(DateTime, nullable=False, index=True)
    seller_id = Column(Integer, ForeignKey('sellers.seller_id'), index=True)
    status = Column(String(20)) # PLACED, PAID, etc.
    total_amount = Column(Numeric(12, 2))
    created_at = Column(DateTime, default=datetime.now(UTC))

class OrderItem(Base):
    __tablename__ = 'order_items'
    order_item_id = Column(BigInteger, primary_key=True)
    order_id = Column(Integer, ForeignKey('orders.order_id'), index=True)
    product_id = Column(Integer, ForeignKey('products.product_id'), index=True)
    order_date = Column(DateTime)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(12, 2), nullable=False)
    subtotal = Column(Numeric(12, 2))
    created_at = Column(DateTime, default=datetime.now(UTC))

class Promotion(Base):
    __tablename__ = 'promotions'
    promotion_id = Column(Integer, primary_key=True)
    promotion_name = Column(String(100))
    promotion_type = Column(String(50))
    discount_type = Column(String(20))
    discount_value = Column(Numeric(10, 2))
    start_date = Column(Date)
    end_date = Column(Date)

class PromotionProduct(Base):
    __tablename__ = 'promotion_products'
    promo_product_id = Column(Integer, primary_key=True)
    promotion_id = Column(Integer, ForeignKey('promotions.promotion_id'))
    product_id = Column(Integer, ForeignKey('products.product_id'))
    created_at = Column(DateTime, default=datetime.now(UTC))