-- Bloco G — View

-- 1. Criar a view vw_pedidos_completos, consolidando pedido, cliente, itens, pagamento e vendedor, 
	-- para servir de base a consultas analíticas futuras.
--> Agrupa o histórico de itens vendidos com contexto demográfico e temporal completo.

CREATE OR REPLACE VIEW vw_pedidos_completos AS 
SELECT
	-- Pedido
	ood.order_id AS pedido,
	ood.order_status AS status,
	ood.order_purchase_timestamp AS data_compra,
	-- Cliente
	ocd.customer_unique_id AS cliente,
	ocd.customer_city AS cidade_cliente,
	ocd.customer_state AS estado_cliente,
	-- Itens
	ooid.product_id AS produto,
	COALESCE(opd.product_category_name, pcnt.product_category_name_english, 'sem_categoria') AS categoria,
	ooid.price AS valor_item,
	ooid.freight_value AS frete_item,
	-- Vendedor
	osd.seller_id AS vendedor,
	osd.seller_city AS cidade_vendedor,
	osd.seller_state AS estado_vendedor,
	-- Subquery: valor total que o cliente pagou pelo pedido
	COALESCE(
	    (
	        SELECT SUM(oopd.payment_value) 
	        FROM olist_order_payments_dataset oopd 
	        WHERE oopd.order_id = ood.order_id
	    ),
	    0.00
	)AS valor_total_pedido
FROM olist_orders_dataset ood 
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id 
JOIN olist_order_items_dataset ooid ON ood.order_id = ooid.order_id 
JOIN olist_sellers_dataset osd ON ooid.seller_id = osd.seller_id
-- Left para produtos sem categoria:
LEFT JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
LEFT JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name;

-- Testes
SELECT * FROM vw_pedidos_completos; -- encontrei 3 linhas com valor total NULL
SELECT DISTINCT pedido FROM vw_pedidos_completos WHERE valor_total_pedido IS NULL; -- bfbd0f9b-def8-4302-105a-d712db648a6c
-- Pedido existe na tabela de itens?
SELECT price, freight_value 
FROM olist_order_items_dataset 
WHERE order_id = 'bfbd0f9b-def8-4302-105a-d712db648a6c';

-- Tabela de pagamentos
SELECT payment_type, payment_value 
FROM olist_order_payments_dataset 
WHERE order_id = 'bfbd0f9b-def8-4302-105a-d712db648a6c';
	-- Solução: COALESCE

-- 2. Criar a view vw_avaliacoes_categoria, consolidando nota média e volume de avaliações por categoria de produto.
--> Identificar quais categorias com maior venda estão gerando maior insatisfação nos clientes

CREATE OR REPLACE VIEW vw_avaliacoes_categoria AS
WITH avaliacao_categorias AS (
	SELECT 
		COALESCE(opd.product_category_name, pcnt.product_category_name_english, 'sem_categoria') AS categoria,
		COUNT(DISTINCT opd.product_id) AS qtd_itens,
		COUNT(DISTINCT oord.review_id) AS qtd_avaliacoes,
		ROUND(AVG(oord.review_score),2) AS nota_media 
	FROM olist_order_reviews_dataset oord
	LEFT JOIN olist_order_items_dataset ooid ON oord.order_id = ooid.order_id 
	LEFT JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id 
	LEFT JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name 
	WHERE ooid.product_id IS NOT NULL 
	GROUP BY categoria
)
SELECT 	
	categoria,
	qtd_itens,
	qtd_avaliacoes,
	nota_media
FROM avaliacao_categorias;

--Teste: TOP 5 categorias com alto volume de vendas e pior reputação
SELECT 
    categoria,
    qtd_avaliacoes AS volume_vendas_avaliadas,
    nota_media,
    CASE 
        WHEN nota_media < 3.5 THEN 'Crítico'
        WHEN nota_media < 4.0 THEN 'Alerta'
        ELSE 'Regular'
    END AS status_de_atendimento
FROM vw_avaliacoes_categoria
WHERE qtd_avaliacoes > 1000
ORDER BY nota_media ASC
LIMIT 5;
-- Temos 610 produtos sem categoria no dataset. Esses 610 produtos sem cadastro geram um impacto de ruído 
	-- em mais de 1.400 avaliações de clientes.
