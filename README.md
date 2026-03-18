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
- **Psycopg2-binary**: Driver kết nối PostgreSQL.
- **Faker**: Sinh dữ liệu giả (Tên, địa chỉ, ngày tháng, công ty...) một cách ngẫu nhiên nhưng thực tế.
- **Python-dotenv**: Quản lý biến môi trường từ file .env.

## 🚀 Hướng dẫn cài đặt và khởi chạy
**1. Cài đặt môi trường**
- Đảm bảo bạn đã cài đặt Poetry. Nếu chưa, hãy cài bằng lệnh: pip install poetry.
- Sau đó, tại thư mục gốc dự án, chạy lệnh để cài đặt các thư viện:
`poetry install`

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