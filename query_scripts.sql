-- Active: 1773765301476@@127.0.0.1@5432@postgres
-- 1. Total revenue per mONth
SELECT 
    DATE_TRUNC('mONth', order_date) AS mONth, 
    SUM(total_amount) AS revenue
FROM orders 
GROUP BY DATE_TRUNC('mONth', order_date);

-- 2. Orders filtered by seller AND date
SELECT 
    seller_id,
    order_date,
    order_id,
    total_amount,
    status
FROM orders
WHERE seller_id = 67
    AND order_date BETWEEN '2025-08-25' AND ' 2025-08-01'

-- 3. Filter data in order_item by product_id
SELECT 
    *
FROM order_items
WHERE product_id = 2001

-- 4. Find order with highest total_amount
SELECT 
    *
FROM orders
ORDER BY total_amount DESC
LIMIT 1

-- 5. List products with highest quantity sold
SELECT
    product_id,
    SUM(quantity) as quantity_sold
FROM order_items
GROUP BY product_id
ORDER BY quantity_sold desc

-- 6. Orders by Seller in October
SELECT 
    seller_id,
    COUNT(*) as order_quantity
FROM orders
WHERE order_date BETWEEN '2025-10-01 00:00:00' AND '2025-10-31 00:00:00'
GROUP BY seller_id

-- 7. Revenue per Product per MONth
SELECT
    DATE_TRUNC('mONth', order_date) AS mONth,
    product_id,
    SUM(subtotal) AS revenue
FROM order_items
GROUP BY DATE_TRUNC('mONth', order_date), product_id
ORDER BY mONth, revenue desc

-- 8. Products Sold per Seller
SELECT
    o.seller_id,
    oi.product_id,
    SUM(quantity)
FROM order_items oi
INNER JOIN orders o
ON oi.order_id = o.order_id
GROUP BY o.seller_id, oi.product_id

-- Partitioning
-- Bảng Orders
ALTER TABLE IF EXISTS orders RENAME TO orders_old;

CREATE TABLE orders (
    order_id INT NOT NUll,
    order_date TIMESTAMP NOT NULL,
    seller_id INT,
    status VARCHAR(20),
    total_amount DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_sellers
FOREIGN KEY (seller_id) 
REFERENCES sellers (seller_id);

CREATE TABLE orders_2025_08 PARTITION OF orders
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE orders_2025_09 PARTITION OF orders
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE orders_2025_10 PARTITION OF orders
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

INSERT INTO orders (order_id, order_date, seller_id, status, total_amount, created_at)
SELECT order_id, order_date, seller_id, status, total_amount, created_at
FROM orders_old;

-- Bảng Order_items
ALTER TABLE IF EXISTS order_items RENAME TO order_items_old;

CREATE TABLE order_items (
    order_item_id BIGINT NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    order_date TIMESTAMP NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    subtotal NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_item_id, order_date)
) PARTITION BY RANGE (order_date);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id, order_date) 
REFERENCES orders (order_id, order_date);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id) 
REFERENCES products (product_id);

CREATE TABLE order_items_2025_08 PARTITION OF order_items
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE order_items_2025_09 PARTITION OF order_items
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE order_items_2025_10 PARTITION OF order_items
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

INSERT INTO order_items (order_item_id, order_id, product_id, order_date, quantity, unit_price, subtotal, created_at)
SELECT order_item_id, order_id, product_id, order_date, quantity, unit_price, subtotal, created_at
FROM order_items_old;

-- Tạo Index cho product_id trong bảng order_items
CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

/* 
    III. Sử dụng Function hoặc Store Procedure để tạo dynamic report
*/

-- 1. Monthly Revenue Report
-- Filter orders by range (start_date to end_date)
CREATE OR REPLACE FUNCTION get_mONthly_revenue_report (start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS TABLE (
    month_period TIMESTAMP,
    total_orders INTEGER,
    total_quantity INTEGER,
    total_revenue NUMERIC(20,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH cte_order_items_by_range_date AS (
        SELECT 
            order_id,
            SUM(quantity) AS quantity
        FROM order_items oi
        WHERE oi.order_date >= DATE_TRUNC('day', start_date::date) 
            AND oi.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
        GROUP BY order_id
    )
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_period,
        CAST(COUNT(DISTINCT o.order_id) as integer) AS total_orders,
        CAST(SUM(quantity) as integer) AS total_quantity,
        CAST(SUM(total_amount) as numeric(20,2)) AS total_revenue
    FROM orders o
    INNER JOIN cte_order_items_by_range_date cte
    ON o.order_id = cte.order_id
    WHERE o.order_date >= DATE_TRUNC('day', start_date::date) 
        AND o.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
        AND o.status = 'DELIVERED'
    GROUP BY DATE_TRUNC('month', o.order_date)
    ORDER BY month_period;
END;
$$ LANGUAGE plpgsql;

-- 2. Daily Revenue Report
-- Filter orders by range (start_date to end_date) AND product list
CREATE OR REPLACE FUNCTION get_daily_revenue_report (start_date TIMESTAMP, end_date TIMESTAMP, product_list INT[])
RETURNS TABLE (
    date_period TIMESTAMP,
    total_orders INT,
    total_quantity INT,
    total_revenue NUMERIC(20,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH cte_order_items_with_filtered_products AS (
        SELECT 
            order_id,
            SUM(quantity) AS quantity
        FROM order_items
        WHERE order_date >= DATE_TRUNC('day', start_date::date) 
            AND order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
            AND (product_list IS NULL OR product_id = ANY (product_list))
        GROUP BY order_id
    )
    SELECT
        DATE_TRUNC('day', o.order_date) AS date_period,
        COUNT(*)::INT AS total_orders,
        SUM(quantity)::INT AS total_quantity,
        SUM(total_amount)::NUMERIC AS total_revenue
    FROM orders o
    INNER JOIN cte_order_items_with_filtered_products cte
    ON o.order_id = cte.order_id
    WHERE o.order_date >= DATE_TRUNC('day', start_date::date) 
        AND o.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
        AND o.status = 'DELIVERED'
    GROUP BY DATE_TRUNC('day', o.order_date)
    ORDER BY date_period;
END;
$$ LANGUAGE plpgsql;

-- 3. Seller Performance Report
-- Filter: Orders within a specific date range. Optional filter by category_id or brand_id
CREATE OR REPLACE FUNCTION get_seller_performance_report (start_date TIMESTAMP, end_date TIMESTAMP, category_id INTEGER DEFAULT NULL, brand_id INTEGER DEFAULT NULL)
RETURNS TABLE (
    seller_id INT,
    seller_name VARCHAR(50),
    total_orders INTEGER,
    total_quantity INTEGER,
    total_revenue NUMERIC(20,2)
) AS $$
DECLARE
	var_category_id INTEGER := category_id;
	var_brand_id INTEGER := brand_id;
BEGIN
    RETURN QUERY
    WITH cte_filtered_product_ids AS (
        SELECT p.product_id
        FROM products p
        WHERE (var_category_id IS NULL OR p.category_id = var_category_id)
            AND (var_brand_id IS NULL OR p.brand_id = var_brand_id)
    ), cte_performance_by_seller_id AS (
        SELECT
            o.seller_id,
            count(distinct o.order_id) as total_orders,
            SUM(f_oi.quantity_per_order ) as total_quantity,
            SUM(o.total_amount ) as total_revenue
        FROM orders o
        INNER JOIN (
            SELECT oi.order_id,
                SUM(quantity) as quantity_per_order
            FROM order_items oi, cte_filtered_product_ids c_ids
            WHERE oi.order_date >= DATE_TRUNC('day', start_date::date)
                AND oi.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
                AND oi.product_id IN (c_ids.product_id)
            GROUP BY oi.order_id
        ) f_oi
        ON o.order_id = f_oi.order_id
        WHERE o.order_date >= DATE_TRUNC('day', start_date::date)
            AND o.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
            AND o.status = 'DELIVERED'
        GROUP BY o.seller_id
    )
    SELECT
        cte.seller_id,
        CAST(s.seller_name AS VARCHAR),
        CAST(cte.total_orders AS INTEGER),
        CAST(cte.total_quantity AS INTEGER),
        CAST(cte.total_revenue AS NUMERIC)
    FROM cte_performance_by_seller_id cte
    INNER JOIN sellers s
    ON cte.seller_id = s.seller_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Top Products per Brand (top 1 sold)
-- Filter: Orders within a specific date range. Optional filter by seller list.
CREATE OR REPLACE FUNCTION get_top_products_per_brand(start_date TIMESTAMP, end_date TIMESTAMP, seller_list INT[] DEFAULT NULL)
RETURNS TABLE (
    brand_id INTEGER,
    brand_name TEXT,
    product_id INTEGER,
    product_name TEXT,
    total_quantity INTEGER,
    total_revenue NUMERIC(20,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH cte_products_filtered_by_seller_list AS (
        SELECT p.product_id,
            p.product_name,
            p.brand_id
        FROM products p
        WHERE (seller_list IS NULL OR p.seller_id = ANY(seller_list))
    ), cte_success_orders AS (
        SELECT
            o.order_id
        FROM orders o
        WHERE o.order_date >= DATE_TRUNC('day', start_date::date)
            AND o.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
            AND o.status = 'DELIVERED'
    ), cte_order_items_quantity AS (
        SELECT
            oi.product_id,
            SUM(oi.quantity) AS qty_per_prod,
            SUM(oi.subtotal) AS amount_per_prod
        FROM order_items oi, cte_products_filtered_by_seller_list c_ids, cte_success_orders c_so
        WHERE oi.order_date >= DATE_TRUNC('day', start_date::date)
            AND oi.order_date < DATE_TRUNC('day', end_date::date + INTERVAL '1 day')
            AND oi.order_id IN (c_so.order_id)
            AND oi.product_id IN (c_ids.product_id)
        GROUP BY oi.product_id
    ), cte_rank_products_by_brand AS (
        SELECT 
            c_prod.brand_id,
            c_prod.product_id,
            c_prod.product_name,
            SUM(c_qty.qty_per_prod) AS total_quantity,
            SUM(c_qty.amount_per_prod) AS total_revenue,
            ROW_NUMBER() OVER (PARTITION BY c_prod.brand_id ORDER BY total_quantity DESC) AS rank_by_brand
        FROM cte_products_filtered_by_seller_list c_prod
        INNER JOIN cte_order_items_quantity c_qty
        ON c_prod.product_id = c_qty.product_id
        GROUP BY c_prod.brand_id,
            c_prod.product_id,
            c_prod.product_name
    )
    SELECT 
        c_rank.brand_id::INT AS brand_id,
        b.brand_name::TEXT AS brand_name,
        c_rank.product_id::INT AS product_id,
        c_rank.product_name::TEXT AS product_name,
        c_rank.total_quantity::INT AS total_quantity,
        c_rank.total_revenue::NUMERIC AS total_revenue
    FROM cte_rank_products_by_brand c_rank
    INNER JOIN brands b
    ON c_rank.brand_id = b.brand_id
    WHERE rank_by_brand = 1 -- lấy highest sold quantity
    ORDER BY brand_id DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. Orders Status Summary
-- Filter: Orders within a specific date range; optionally filter by seller list or category list.
CREATE OR REPLACE FUNCTION get_orders_status_summary(start_date TIMESTAMP, end_date TIMESTAMP, seller_list INT[] DEFAULT NULL, category_list INT[] DEFAULT NULL)
RETURNS TABLE (
    status VARCHAR(20),
    total_orders INT,
    total_revenue NUMERIC(20,2)
) AS $$
BEGIN
    IF category_list IS NOT NULL THEN
        RETURN QUERY
        WITH cte_orders_by_category_list AS (
            SELECT
                oi.order_id,
                SUM(oi.subtotal) AS total_amount
            FROM order_items oi
            INNER JOIN products p
                ON oi.product_id = p.product_id
            WHERE oi.order_date >= DATE_TRUNC('day', start_date::TIMESTAMP)
                AND oi.order_date < DATE_TRUNC('day', end_date::TIMESTAMP + INTERVAL '1 day')
                AND p.category_id = ANY(category_list)
            GROUP BY oi.order_id
        ), cte_group_status AS (
            SELECT 
                o.order_id,
                o.status,
                CASE
                    WHEN o.status IN ('PLACED', 'PAID', 'SHIPPED') THEN 'Pending'
                    WHEN o.status = 'DELIVERED' THEN 'Completed'
                    WHEN o.status IN ('CANCELLED', 'RETURNED') THEN 'Cancelled'
                END AS status_group
            FROM orders o
            WHERE o.order_date >= DATE_TRUNC('day', start_date::TIMESTAMP)
                AND o.order_date < DATE_TRUNC('day', end_date::TIMESTAMP + INTERVAL '1 day')
                AND (seller_list IS NULL OR o.seller_id = ANY(seller_list))
        )
        SELECT 
            status_group::VARCHAR,
            COUNT(*)::INT AS total_orders,
            SUM(c_cat.total_amount)::NUMERIC AS total_revenue
        FROM cte_group_status c_gr
        INNER JOIN cte_orders_by_category_list c_cat
            ON c_gr.order_id = c_cat.order_id
        GROUP BY status_group;
    ELSE
        RETURN QUERY
        WITH cte_group_status AS (
            SELECT 
                o.order_id,
                o.status,
                o.total_amount,
                CASE
                    WHEN o.status IN ('PLACED', 'PAID', 'SHIPPED') THEN 'Pending'
                    WHEN o.status = 'DELIVERED' THEN 'Completed'
                    WHEN o.status IN ('CANCELLED', 'RETURNED') THEN 'Cancelled'
                END AS status_group
            FROM orders o
            WHERE o.order_date >= DATE_TRUNC('day', start_date::TIMESTAMP)
                AND o.order_date < DATE_TRUNC('day', end_date::TIMESTAMP + INTERVAL '1 day')
                AND (seller_list IS NULL OR o.seller_id = ANY(seller_list))
        )
        SELECT 
            status_group::VARCHAR,
            COUNT(*)::INT AS total_orders,
            SUM(total_amount)::NUMERIC AS total_revenue
        FROM cte_group_status cte
        GROUP BY status_group;
        
    END IF;
END;
$$ LANGUAGE plpgsql;