DROP TABLE IF EXISTS sales.orders;

CREATE TABLE IF NOT EXISTS sales.orders
(
    order_id text COLLATE pg_catalog."default" NOT NULL,
    order_date date,
    status text COLLATE pg_catalog."default",
    fulfilment text COLLATE pg_catalog."default",
    sales_channel text COLLATE pg_catalog."default",
    ship_service_level text COLLATE pg_catalog."default",
    sku text COLLATE pg_catalog."default",
    qty integer,
    currency text COLLATE pg_catalog."default",
    amount numeric,
    promotion_ids text COLLATE pg_catalog."default",
    b2b boolean,
    CONSTRAINT orders_pkey PRIMARY KEY (order_id)
)

DROP TABLE IF EXISTS sales.products;

CREATE TABLE IF NOT EXISTS sales.products
(
    sku text COLLATE pg_catalog."default",
    style text COLLATE pg_catalog."default",
    category text COLLATE pg_catalog."default",
    size text COLLATE pg_catalog."default",
    asin text COLLATE pg_catalog."default"
)

DROP TABLE IF EXISTS sales.shipping;

CREATE TABLE IF NOT EXISTS sales.shipping
(
    order_id text COLLATE pg_catalog."default" NOT NULL,
    courier_status text COLLATE pg_catalog."default",
    ship_city text COLLATE pg_catalog."default",
    ship_state text COLLATE pg_catalog."default",
    ship_postal_code text COLLATE pg_catalog."default",
    ship_country text COLLATE pg_catalog."default",
    fulfilled_by text COLLATE pg_catalog."default",
    CONSTRAINT shipping_pkey PRIMARY KEY (order_id),
    CONSTRAINT shipping_order_id_fkey FOREIGN KEY (order_id)
        REFERENCES sales.orders (order_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

