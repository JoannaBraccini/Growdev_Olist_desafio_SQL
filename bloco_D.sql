-- Bloco D — Subqueries

-- 1. Clientes cujo gasto total está acima da média geral de gasto por cliente.
--> Identifica os clientes cujo consumo acumulado supera a média da plataforma, útil para ações de fidelização.
SELECT 
    ocd.customer_unique_id AS cliente,
    SUM(oopd.payment_value) AS gasto_total_cliente
FROM olist_customers_dataset ocd
JOIN olist_orders_dataset ood ON ocd.customer_id = ood.customer_id
JOIN olist_order_payments_dataset oopd ON ood.order_id = oopd.order_id
GROUP BY cliente 
HAVING SUM(oopd.payment_value) > (
    -- Subquery: média geral de gasto considerando o que cada cliente gastou no total
    SELECT AVG(gasto_por_cliente)
    FROM (
        SELECT SUM(oopd2.payment_value) AS gasto_por_cliente
        FROM olist_customers_dataset ocd2 
        JOIN olist_orders_dataset ood2 ON ocd2.customer_id = ood2.customer_id
        JOIN olist_order_payments_dataset oopd2 ON ood2.order_id = oopd2.order_id
        GROUP BY ocd2.customer_unique_id
    )
)
ORDER BY gasto_total_cliente DESC;

-- 2. Produtos que nunca receberam avaliação (NOT EXISTS / NOT IN).
--> Identifica produtos sem feedback na plataforma, podendo-se direcionar campanhas de engajamento ou auditoria de catálogo.
SELECT 
    opd.product_id AS produto,
    opd.product_category_name AS categoria
FROM olist_products_dataset opd
WHERE NOT EXISTS (
    SELECT 1 
    FROM olist_order_items_dataset ooid 
    JOIN olist_order_reviews_dataset oord ON ooid.order_id = oord.order_id
    WHERE ooid.product_id = opd.product_id
)
ORDER BY categoria;

-- 3. Vendedores que venderam produtos de mais de 5 categorias diferentes (subquery com COUNT(DISTINCT ...)).
--> Identifica vendedores com portfólio diversificado que atuam em mais de 5 categorias diferentes.
SELECT 
	seller_id AS vendedor, 
	seller_city AS cidade, 
	seller_state AS estado
FROM olist_sellers_dataset
WHERE seller_id IN (
    -- Subquery: filtra os vendedores com mais de 5 categorias
    SELECT ooid.seller_id
    FROM olist_order_items_dataset ooid 
    JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
    GROUP BY ooid.seller_id
    HAVING COUNT(DISTINCT opd.product_category_name) > 5
);

-- 4. Pedidos cujo valor de frete (freight_value) é maior que o valor total dos itens do próprio pedido 
	-- (subquery correlacionada comparando as duas somas).
--> Identifica pedidos cujo custo logístico superou o valor dos produtos, exibindo ambos os totais lado a lado.
SELECT 
    ooid.order_id AS pedido,
    SUM(ooid.freight_value) AS frete_total_pedido,
    -- Subquery 1: exibe o valor total dos produtos do mesmo pedido
    (
        SELECT SUM(ooid2.price)
        FROM olist_order_items_dataset ooid2 
        WHERE ooid2.order_id = ooid.order_id
    ) AS valor_total_produtos
FROM olist_order_items_dataset ooid 
GROUP BY ooid.order_id
HAVING SUM(ooid.freight_value) > (
    -- Subquery correlacionada: filtro comparando as duas somas
    SELECT SUM(ooid3.price)
    FROM olist_order_items_dataset ooid3 
    WHERE ooid3.order_id = ooid.order_id
)
ORDER BY frete_total_pedido DESC;
