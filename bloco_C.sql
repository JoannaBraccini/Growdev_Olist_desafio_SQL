-- Bloco C — Funções agregadas + GROUP BY + HAVING

-- 1. Faturamento total por estado do cliente.
--> Calcula a receita gerada por estado do cliente, útil para identificar os mercados regionais mais lucrativos.
SELECT 
    ocd.customer_state AS estado_cliente,
    SUM(oopd.payment_value) AS faturamento_total
FROM olist_customers_dataset ocd
JOIN olist_orders_dataset ood ON ocd.customer_id = ood.customer_id
JOIN olist_order_payments_dataset oopd ON ood.order_id = oopd.order_id
GROUP BY estado_cliente 
ORDER BY faturamento_total DESC;

-- 2. Top 10 vendedores por faturamento.
--> Identifica os 10 vendedores líderes em receita acumulada, pode ser usado para programas de relacionamento ou comissão.
SELECT 
    ooid.seller_id AS vendendor,
    osd.seller_city AS cidade_vendedor,
    osd.seller_state AS estado_vendedor,
    SUM(ooid.price) AS faturamento_total
FROM olist_order_items_dataset ooid
JOIN olist_sellers_dataset osd ON ooid.seller_id = osd.seller_id
GROUP BY vendendor, cidade_vendedor, estado_vendedor 
ORDER BY faturamento_total DESC LIMIT 10;

-- 3. Ticket médio por categoria de produto.
--> Pode ser usado para direcionar estratégias de precificação e margem de lucro.
SELECT 
    opd.product_category_name AS categoria,
    ROUND(AVG(ooid.price), 2) AS ticket_medio,
    COUNT(DISTINCT ooid.order_id) AS total_pedidos -- Sem o distinct, cada item do pedido contaria como um pedido diferente.
FROM olist_order_items_dataset ooid
JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
GROUP BY categoria 
ORDER BY ticket_medio DESC;

-- 4. Vendedores com nota média de avaliação abaixo de 3 (HAVING AVG(...) < 3).
--> Identificar parceiros com baixo desempenho pode ser útil para planos de auditoria ou suspensão da conta.
SELECT 
    ooid.seller_id AS vendedor,
    ROUND(AVG(oord.review_score), 2) AS nota_media
FROM olist_order_items_dataset ooid
JOIN olist_orders_dataset o ON ooid.order_id = o.order_id
JOIN olist_order_reviews_dataset oord ON o.order_id = oord.order_id
GROUP BY vendedor 
HAVING AVG(oord.review_score) < 3
ORDER BY nota_media ASC;

-- 5. Quantidade de pedidos por forma de pagamento (GROUP BY payment_type).
--> Identifica o tipo de pagamento mais utilizado.
SELECT 
    payment_type AS forma_pagamento,
    COUNT(DISTINCT order_id) AS total_pedidos
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_pedidos DESC;

-- 6. Peso médio dos produtos por categoria.
--> Embasa negociações de valores de frete com transportadoras.
SELECT 
    product_category_name AS categoria,
    ROUND(AVG(product_weight_g), 2) AS peso_medio_gramas
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY peso_medio_gramas DESC;

-- 7. Número médio de parcelas (AVG(payment_installments)) por categoria de produto.
--> Analisa o perfil de parcelamento por departamento, mapeando a média de parcelas.
SELECT 
    opd.product_category_name AS categoria,
    ROUND(AVG(oopd.payment_installments), 1) AS media_parcelas
FROM olist_order_items_dataset ooid
JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
JOIN olist_order_payments_dataset oopd ON ooid.order_id = oopd.order_id 
GROUP BY categoria 
ORDER BY media_parcelas DESC;

