--command " "\\copy sales.shipping (order_id, courier_status, ship_city, ship_state, ship_postal_code, ship_country, fulfilled_by) FROM 'C:/Users/mohin/Desktop/UMD/DB_SYS~1/PROJEC~1/PROJEC~1/shipping.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '''';""

--command " "\\copy sales.products (sku, style, category, size, asin) FROM 'C:/Users/mohin/Desktop/UMD/DB_SYS~1/PROJEC~1/PROJEC~1/products.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '''';""

--command " "\\copy sales.orders (order_id, order_date, status, fulfilment, sales_channel, ship_service_level, sku, qty, currency, amount, promotion_ids, b2b) FROM 'C:/Users/mohin/Desktop/UMD/DB_SYS~1/PROJEC~1/PROJEC~1/orders.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '''';""