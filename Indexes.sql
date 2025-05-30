-- Indexes on orders table
CREATE INDEX orders_orderid_idx ON sales.orders(order_date);
CREATE INDEX orders_orderdate_idx ON sales.orders(order_date);
-- Indexes on products table
CREATE INDEX products_sku_idx ON sales.products(sku);
CREATE INDEX products_category_idx ON sales.products(category);
-- Indexes on shipping table
CREATE INDEX shipping_orderid_idx ON sales.shipping(order_id);