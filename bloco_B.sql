-- Bloco B — JOINs

-- 1. Relatório com categoria do produto (traduzida), valor do item, cidade do vendedor.
--> Identifica a distribuição geográfica e precificação de categorias por polo de vendedores, útil para otimizar a logística regional.
SELECT 
    pcnt.product_category_name_english AS categoria_ingles,
    opd.product_category_name AS categoria_portugues,
    ooid.price AS valor_item,
    osd.seller_city AS cidade_vendedor
FROM olist_order_items_dataset ooid
JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
JOIN olist_sellers_dataset osd ON ooid.seller_id = osd.seller_id
LEFT JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name
ORDER BY valor_item DESC;

-- 2. Identificar pedidos com atraso na entrega, comparando data estimada com data real de entrega (join entre orders e customers).
--> Identifica entregas atrasadas cruzando datas do pedido com a localização do cliente, pode ser usado para mapear gargalos logísticos regionais.
SELECT 
    ood.order_id AS pedido,
    ood.order_status AS status,
    ood.order_estimated_delivery_date AS data_estimada,
    ood.order_delivered_customer_date AS data_entrega_real,
    (ood.order_delivered_customer_date - ood.order_estimated_delivery_date) AS atraso,
    ocd.customer_city AS cidade_cliente,
    ocd.customer_state AS estado_cliente
FROM olist_orders_dataset ood
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id
WHERE ood.order_status = 'delivered'
AND ood.order_delivered_customer_date > ood.order_estimated_delivery_date
ORDER BY atraso DESC;

-- 3. Listar pedidos e suas formas de pagamento, incluindo pedidos pagos em mais de uma parcela (join entre orders e order_payments).
--> Pode ser usado para analisar o fluxo de caixa mapeando as formas de pagamento e o volume de parcelamentos escolhidos pelos clientes.
SELECT 
    ood.order_id AS pedido,
    oopd.payment_type AS forma_pagamento,
    oopd.payment_installments AS parcelas,
    oopd.payment_value AS valor_pagamento
FROM olist_orders_dataset ood
JOIN olist_order_payments_dataset oopd ON ood.order_id = oopd.order_id
ORDER BY oopd.payment_installments DESC, oopd.payment_value DESC;

-- 4. Listar produtos junto com a categoria traduzida, incluindo produtos cuja categoria não possui tradução cadastrada (LEFT JOIN com product_category_name_translation).
--> Oferece visibilidade total do catálogo mapeando produtos com suas traduções sem ocultar itens com categorias pendentes.
SELECT 
    opd.product_id AS produto,
    opd.product_category_name AS categoria_original,
    pcnt.product_category_name_english AS categoria_traduzida
FROM olist_products_dataset opd
LEFT JOIN product_category_name_translation pcnt 
ON opd.product_category_name = pcnt.product_category_name
ORDER BY categoria_traduzida;

-- 5. Identificar pedidos em que o cliente e o vendedor são do mesmo estado (join entre customers, orders, order_items e sellers).
-- Identifica transações locais, útil para analisar padrões de comércio regional e oportunidades de frete reduzido.
SELECT 
    ood.order_id AS pedido,
    ood.order_status AS status,
    ocd.customer_state AS estado_cliente,
    osd.seller_state AS estado_vendedor,
    ocd.customer_city AS cidade_cliente,
    osd.seller_city AS cidade_vendedor
FROM olist_orders_dataset ood
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id
JOIN olist_order_items_dataset ooid ON ood.order_id = ooid.order_id
JOIN olist_sellers_dataset osd ON ooid.seller_id = osd.seller_id
WHERE ocd.customer_state = osd.seller_state
ORDER BY pedido;
