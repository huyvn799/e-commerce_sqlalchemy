# 🛒E-Commerce Database with SQLAlchemy and Faker
## 📝 Mô tả dự án
- Dự án này là một hệ thống tự động hóa việc khởi tạo cấu trúc cơ sở dữ liệu (Database Schema) và tạo dữ liệu giả lập (Synthetic Data) cho hệ thống thương mại điện tử (OLTP).

- Mục tiêu chính là xây dựng một nền tảng dữ liệu có quan hệ chặt chẽ, phục vụ cho việc kiểm thử hiệu năng, xây dựng các báo cáo phân tích hoặc làm nguồn cấp (Source) cho các pipeline ETL sau này.

## 📂 Cấu trúc dự án (Project Structure)
- Dự án được tổ chức theo mô hình Modular, giúp tách biệt logic nghiệp vụ và quản trị hệ thống:
```
project_03/
├── database/
│   ├── __init__.py
│   ├── connection.py   # Quản lý kết nối, kiểm tra và provisioning Database
│   └── models.py       # Định nghĩa Schema (ORM) dựa trên SQLAlchemy
├── data_generator/
│   ├── __init__.py
│   └── seeder.py       # Logic sinh dữ liệu giả bằng thư viện Faker
├── .env                # Lưu trữ thông tin nhạy cảm (Credentials)
├── pyproject.toml      # Quản lý thư viện bằng Poetry
├── main.py             # Entry point - Điều phối toàn bộ quy trình
└── README.md           # Hướng dẫn dự án
```
## 🛠 Thư viện sử dụng (Library)
- **Python 3.10+**
- **Poetry**: Quản lý môi trường ảo và thư viện.
- **SQLAlchemy**: Thư viện ORM mạnh mẽ để mapping dữ liệu Python và SQL.
- **PostgreSQL**: Database
- **Psycopg2-binary**: Driver kết nối PostgreSQL.
- **Faker**: Sinh dữ liệu giả (Tên, địa chỉ, ngày tháng, công ty...) một cách ngẫu nhiên nhưng thực tế.
- **Python-dotenv**: Quản lý biến môi trường từ file .env.

## 🚀 Hướng dẫn cài đặt và khởi chạy
**1. Cài đặt môi trường**
- Đảm bảo bạn đã cài đặt Poetry. Nếu chưa, hãy cài bằng lệnh: pip install poetry.
- Sau đó, tại thư mục gốc dự án, chạy lệnh để cài đặt các thư viện:
`poetry install`
- Tạo database postgreSQL đặt tên là `ecommerce_db`

**2. Cấu hình Database**
- Tạo file .env tại thư mục gốc và nhập thông tin PostgreSQL của bạn:
```
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecommerce_db
```
**3. Chạy chương trình**
- Kích hoạt môi trường ảo và thực thi script chính:
`poetry run python main.py`

## ⚙️ Quy trình xử lý (Workflow)
1. **Load Environment**: Hệ thống đọc cấu hình từ file .env.

2. **Database Provisioning**: Kết nối tới server, kiểm tra xem database mục tiêu đã tồn tại chưa. Nếu chưa, hệ thống tự động chạy lệnh CREATE DATABASE.

3. **Schema Initialization**: SQLAlchemy quét các class trong models.py để tạo ra các bảng với đầy đủ ràng buộc (Primary Key, Foreign Key, Constraints).

4. **Data Seeding**:
- Tạo các bảng danh mục (Brands, Categories, Sellers).
- Tạo 2000 sản phẩm gắn với các ID ngẫu nhiên từ các bảng trên.
- Tạo các chương trình khuyến mãi (Promotions) với logic thời gian thực tế.
- Liên kết sản phẩm và khuyến mãi (PromotionProduct).
- Tạo 3 triệu đơn hàng với chi tiết đơn hàng phụ thuộc seller của sản phấm đó
- Phân bổ tỉ lệ đơn hàng theo 6 trạng thái:
    - DELIVERED: 70%
    - SHIPPED: 11%
    - CANCELLED: 7%
    - PLACED: 5%
    - PAID: 4%
    - RETURNED: 3%
- Chi tiết đơn hàng: mỗi đơn hàng sẽ gồm 3-5 sản phẩm, mỗi sản phẩm có số lượng ngẫu nhiên từ 1 đến 5

5. **Thực hiện query SQL trong file ```query_scripts.sql```**
- Thực hiện các câu query theo yêu cầu sau:
    1. Total revenue per month
    2. Orders filtered by seller and date
    3. Filter data in order_item by product_id
    4. Find order with highest total_amount
    5. List products with highest quantity sold
    6. Orders by Seller in October
    7. Revenue per Product per Month
    8. Products Sold per Seller
- So sánh kết quả trước và sau khi sử dụng partitioning cho bảng orders, order_items và indexing cho bảng order_items (product_id)
- Hình ảnh snapshot kết quả bao gồm **Run-time** và **Execution Plan** ở trong folder ```snapshot```
- Viết các function, store procedure theo yêu cầu sau:
    1. Monthly Revenue Report
    - **Goal:** Show total revenue and total orders per month.
    - **Columns:** `month`, `total_orders`, `total_quantity`, `total_revenue`
    - **Filter:** Orders within a specific date range (`start_date` to `end_date`)
    2. Daily Revenue Report
    - **Goal:** Show total revenue and total orders per month.
    - **Columns:** `date`, `total_orders`, `total_quantity`, `total_revenue`
    - **Filter:** Orders within a specific date range (`start_date` to `end_date`) and *product list*
    3. Seller Performance Report
    - **Goal:** Compare sellers by total revenue and quantity sold.
    - **Columns:** `seller_id`, `seller_name`, `total_orders`, `total_quantity`, `total_revenue`
    - **Filter:** Orders within a specific date range. Optional filter by `category_id` or `brand_id`.
    4. Top Products per Brand
    - **Goal:** Identify top products for each brand by quantity sold.
    - **Columns:** `brand_id`, `brand_name`, `product_id`, `product_name`, `total_quantity`, `total_revenue`
    - **Filter:** Orders within a specific date range. Optional filter by *seller list.*
    5. Orders Status Summary
    - **Goal:** Count orders per status (completed, pending, cancelled).
    - **Columns:** `status`, `total_orders`, `total_revenue`
    - **Filter:** Orders within a specific date range; optionally filter by seller list or category list.
