-- Bloco A — SELECT básico

-- 1. Listar os 20 pedidos com status delivered mais recentes, ordenados pela data de entrega.
--> Identifica as entregas concluídas mais recentes, pode ser usado para monitorar a eficiência logística.
SELECT 
    order_id AS pedido, 
    customer_id AS cliente, 
    order_status AS status_pedido, 
    order_delivered_customer_date AS data_entrega
FROM olist_orders_dataset 
WHERE order_status = 'delivered' 
AND order_delivered_customer_date IS NOT NULL
ORDER BY order_delivered_customer_date DESC 
LIMIT 20;

-- 2. Listar todos os produtos de uma categoria específica (usando a tabela de tradução para filtrar pelo nome em português).
--> Retorna o portfólio completo de produtos de uma categoria específica, permite analisar as especificações dos itens concorrentes do mesmo segmento.
SELECT 
	opd.product_id AS produto, 
	opd.product_category_name AS categoria, 
	pcnt.product_category_name_english AS categoria_traduzida
FROM olist_products_dataset opd
JOIN product_category_name_translation pcnt  
ON opd.product_category_name = pcnt.product_category_name
WHERE opd.product_category_name = 'beleza_saude';

-- 3. Listar os métodos de pagamento distintos utilizados na base (SELECT DISTINCT payment_type).
--> Mapeia as formas de pagamento aceitas, pode ser usado para identificar as preferências dos clientes.
SELECT DISTINCT payment_type 
FROM olist_order_payments_dataset;

-- 4. Listar os produtos com peso (product_weight_g) acima de 10kg, ordenados do mais pesado para o mais leve.
--> Identifica produtos pesados, útil para planejar estratégias de frete diferenciado ou auxiliar a equipe de logística na triagem.
SELECT 
    product_id AS produto,
    product_category_name AS categoria,
    product_weight_g AS peso_gramas
FROM olist_products_dataset
WHERE product_weight_g > 10000
ORDER BY product_weight_g DESC;
