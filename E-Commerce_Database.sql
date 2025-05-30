--Total Revenue by Month
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    round(SUM(amount),2) AS total_revenue
FROM sales.orders
GROUP BY month
ORDER BY month;

-- Top 5 Best-Selling Products by Quantity
SELECT 
    o.sku,
    SUM(o.qty) AS total_qty,
    p.category
FROM sales.orders o
JOIN sales.products p ON o.sku = p.sku
GROUP BY o.sku, p.category
ORDER BY total_qty DESC
LIMIT 5;

-- Orders That Were Cancelled But Shipped
SELECT o.order_id, o.status, s.courier_status
FROM sales.orders o
JOIN sales.shipping s ON o.order_id = s.order_id
WHERE o.status ILIKE 'cancelled%' AND s.courier_status ILIKE 'shipped%';

--Count of Orders That Were Cancelled But Shipped Using Ineer Query
SELECT COUNT(*) AS cancelled_but_shipped
FROM (
    SELECT o.order_id
    FROM sales.orders o
    JOIN sales.shipping s ON o.order_id = s.order_id
    WHERE o.status ILIKE 'cancelled%' 
      AND s.courier_status ILIKE 'shipped%'
) AS cancelled_shipped_orders;

-- Average Order Value (AOV)
SELECT 
    AVG(amount) AS avg_order_value
FROM sales.orders;

-- Repeat Products (Ordered in More Than One Order)
SELECT 
    o.sku,
    p.style,
    p.category,
    p.size,
    p.asin,
    COUNT(DISTINCT o.order_id) AS orders_appeared_in
FROM sales.orders o
JOIN sales.products p ON o.sku = p.sku
GROUP BY o.sku, p.style, p.category, p.size, p.asin
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY orders_appeared_in DESC;

--Customer Lifetime Value CLV
SELECT
    ship_postal_code,
    ship_country,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.amount) AS total_revenue,
    AVG(o.amount) AS avg_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    (MAX(o.order_date) - MIN(o.order_date)) AS customer_lifetime_days
FROM sales.orders o
JOIN sales.shipping s ON o.order_id = s.order_id
WHERE o.status ILIKE 'shipped%'
GROUP BY ship_postal_code, ship_country
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_revenue DESC
LIMIT 10;

-- Sales by Category

SELECT 
    p.category, 
    round(SUM(o.amount),3) AS total_sales
FROM     sales.orders o
JOIN     sales.products p ON o.sku = p.sku
GROUP BY p.category
ORDER BY total_sales DESC;

--Sales by Region
SELECT     s.ship_state, 
    ROUND(SUM(o.amount),3) AS total_sales
FROM     sales.shipping s
JOIN     sales.orders o ON s.order_id = o.order_id
GROUP BY     s.ship_state
ORDER BY     total_sales DESC;

-- Products with high return rates using window functions

WITH product_returns AS (
  SELECT 
    p.sku,
    p.category,
    SUM(CASE WHEN o.status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    COUNT(o.order_id) AS total_orders
  FROM sales.orders o
  JOIN sales.products p ON o.sku = p.sku
  GROUP BY p.sku, p.category
)

SELECT 
  sku,
  category,
  returned_orders,
  total_orders,
  (returned_orders::FLOAT / NULLIF(total_orders, 0)) * 100 AS return_rate,
  RANK() OVER (ORDER BY (returned_orders::FLOAT / NULLIF(total_orders, 0)) DESC) AS return_rank
FROM product_returns
WHERE total_orders > 0
ORDER BY return_rate DESC
LIMIT 10;

---------------------
--Customer Behavior Analysis

WITH customer_orders AS (
    SELECT
        s.ship_postal_code,
        s.ship_country,
        o.order_id,
        o.order_date,
        o.amount,
        ROW_NUMBER() OVER (
            PARTITION BY s.ship_postal_code, s.ship_country 
            ORDER BY o.order_date
        ) AS order_rank,
        COUNT(*) OVER (
            PARTITION BY s.ship_postal_code, s.ship_country
        ) AS total_orders,
        SUM(o.amount) OVER (
            PARTITION BY s.ship_postal_code, s.ship_country
        ) AS total_spent,
        AVG(o.amount) OVER (
            PARTITION BY s.ship_postal_code, s.ship_country
        ) AS avg_order_value,
        MIN(o.order_date) OVER (
            PARTITION BY s.ship_postal_code, s.ship_country
        ) AS first_order_date,
        MAX(o.order_date) OVER (
            PARTITION BY s.ship_postal_code, s.ship_country
        ) AS last_order_date,
        LAG(o.order_date) OVER (
            PARTITION BY s.ship_postal_code, s.ship_country 
            ORDER BY o.order_date
        ) AS previous_order_date
    FROM sales.orders o
    JOIN sales.shipping s ON o.order_id = s.order_id
    WHERE o.status ILIKE 'shipped%'
),

customer_behavior_summary AS (
    SELECT DISTINCT
        ship_postal_code,
        ship_country,
        total_orders,
        total_spent,
        avg_order_value,
        first_order_date,
        last_order_date,
        (last_order_date - first_order_date) AS customer_lifetime_days,
        AVG(order_date - previous_order_date) OVER (
            PARTITION BY ship_postal_code, ship_country
        ) AS avg_days_between_orders
    FROM customer_orders
)

SELECT *
FROM customer_behavior_summary
ORDER BY total_spent DESC
LIMIT 10;

-----------------------------PERFORMANCE ANANLYSIS

DROP INDEX IF EXISTS orders_orderid_idx;
DROP INDEX IF EXISTS orders_orderdate_idx;
DROP INDEX IF EXISTS orders_sku_idx;
DROP INDEX IF EXISTS products_sku_idx;
DROP INDEX IF EXISTS products_category_idx;
DROP INDEX IF EXISTS shipping_orderid_idx;



-- Products with high return rates using window functions
EXPLAIN ANALYZE
WITH product_returns AS (
  SELECT 
    p.sku,
    p.category,
    SUM(CASE WHEN o.status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    COUNT(o.order_id) AS total_orders
  FROM sales.orders o
  JOIN sales.products p ON o.sku = p.sku
  GROUP BY p.sku, p.category
)

SELECT 
  sku,
  category,
  returned_orders,
  total_orders,
  (returned_orders::FLOAT / NULLIF(total_orders, 0)) * 100 AS return_rate,
  RANK() OVER (ORDER BY (returned_orders::FLOAT / NULLIF(total_orders, 0)) DESC) AS return_rank
FROM product_returns
WHERE total_orders > 0
ORDER BY return_rate DESC
LIMIT 10;

ANALYZE VERBOSE sales.orders;
ANALYZE VERBOSE sales.products;
ANALYZE VERBOSE sales.shipping;


-- Products with high return rates using window functions
EXPLAIN ANALYZE
WITH product_returns AS (
  SELECT 
    p.sku,
    p.category,
    SUM(CASE WHEN o.status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    COUNT(o.order_id) AS total_orders
  FROM sales.orders o
  JOIN sales.products p ON o.sku = p.sku
  GROUP BY p.sku, p.category
)

SELECT 
  sku,
  category,
  returned_orders,
  total_orders,
  (returned_orders::FLOAT / NULLIF(total_orders, 0)) * 100 AS return_rate,
  RANK() OVER (ORDER BY (returned_orders::FLOAT / NULLIF(total_orders, 0)) DESC) AS return_rank
FROM product_returns
WHERE total_orders > 0
ORDER BY return_rate DESC
LIMIT 10;

-- Indexes on orders table
CREATE INDEX orders_orderid_idx ON sales.orders(order_date);
CREATE INDEX orders_orderdate_idx ON sales.orders(order_date);
-- Indexes on products table
CREATE INDEX products_sku_idx ON sales.products(sku);
CREATE INDEX products_category_idx ON sales.products(category);
-- Indexes on shipping table
CREATE INDEX shipping_orderid_idx ON sales.shipping(order_id);

ANALYZE VERBOSE sales.orders;
ANALYZE VERBOSE sales.products;
ANALYZE VERBOSE sales.shipping;


-- Products with high return rates using window functions
EXPLAIN ANALYZE
WITH product_returns AS (
  SELECT 
    p.sku,
    p.category,
    SUM(CASE WHEN o.status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    COUNT(o.order_id) AS total_orders
  FROM sales.orders o
  JOIN sales.products p ON o.sku = p.sku
  GROUP BY p.sku, p.category
)

SELECT 
  sku,
  category,
  returned_orders,
  total_orders,
  (returned_orders::FLOAT / NULLIF(total_orders, 0)) * 100 AS return_rate,
  RANK() OVER (ORDER BY (returned_orders::FLOAT / NULLIF(total_orders, 0)) DESC) AS return_rank
FROM product_returns
WHERE total_orders > 0
ORDER BY return_rate DESC
LIMIT 10;
