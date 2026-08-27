-- ENUMs
CREATE TYPE payment_type AS ENUM ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined');
CREATE TYPE order_status AS ENUM ('delivered', 'shipped', 'canceled', 'unavailable', 'invoiced', 'processing', 'approved', 'created');

-- Tabelas

-- CLIENTES
CREATE TABLE olist_customers_dataset (
    customer_id UUID PRIMARY KEY,
    customer_unique_id UUID NOT NULL,
    customer_zip_code_prefix CHAR(5) NOT NULL,
    customer_city VARCHAR(50),
    customer_state CHAR(2)
);
-- GEOLOCALIZAÇÃO
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix CHAR(5),
    geolocation_lat FLOAT8, -- (double precision)
    geolocation_lng FLOAT8,
    geolocation_city VARCHAR(50),
    geolocation_state CHAR(2)
);
-- VENDEDORES
CREATE TABLE olist_sellers_dataset (
    seller_id UUID PRIMARY KEY,
    seller_zip_code_prefix CHAR(5) NOT NULL,
    seller_city VARCHAR(50),
    seller_state CHAR(2)
);
-- PRODUTOS
CREATE TABLE olist_products_dataset (
    product_id UUID PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
-- PEDIDOS
CREATE TABLE olist_orders_dataset (
    order_id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    order_status order_status,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES olist_customers_dataset(customer_id)
);
-- ITENS DOS PEDIDOS
CREATE TABLE olist_order_items_dataset (
    order_id UUID,
    order_item_id INT,
    product_id UUID NOT NULL,
    seller_id UUID NOT NULL,
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10, 2) NOT NULL,
    freight_value DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_items_orders FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_products FOREIGN KEY (product_id) REFERENCES olist_products_dataset(product_id),
    CONSTRAINT fk_items_sellers FOREIGN KEY (seller_id) REFERENCES olist_sellers_dataset(seller_id)
);
-- PAGAMENTOS
CREATE TABLE olist_order_payments_dataset (
    order_id UUID,
    payment_sequential INT,
    payment_type payment_type),
    payment_installments INT,
    payment_value DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id) ON DELETE CASCADE
);
-- REVIEWS
CREATE TABLE olist_order_reviews_dataset (
    review_id UUID PRIMARY KEY,
    order_id UUID NOT NULL,
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    CONSTRAINT fk_reviews_orders FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id) ON DELETE CASCADE
);
-- TRADUÇÃO DAS CATEGORIAS
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(50),
    product_category_name_english VARCHAR(50)
);