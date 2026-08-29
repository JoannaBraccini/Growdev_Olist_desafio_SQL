-- Bloco H — Procedure de leitura (parametrizada)

-- 1. Criar a procedure/function sp_relatorio_vendedor(id_vendedor, data_inicio, data_fim), que retorna
	-- faturamento, ticket médio e nota média de avaliação do vendedor no período informado — sem alterar nenhum dado.
--> Extrai o relatório de performance do vendedor buscado
CREATE OR REPLACE FUNCTION sp_relatorio_vendedor(
    p_id_vendedor UUID,
    p_data_inicio TIMESTAMP,
    p_data_fim TIMESTAMP 
)
RETURNS TABLE (
	id_vendedor_buscado UUID,
    faturamento_total NUMERIC,
    ticket_medio NUMERIC,
    media_avaliacao NUMERIC
) 
LANGUAGE plpgsql -- Linguagem de programação procedural (PL/pgSQL)
AS $$ -- Indicador de começo da função
BEGIN
    RETURN QUERY
		SELECT
			p_id_vendedor,
			SUM(ooid.price),
			ROUND(AVG(ooid.price),2),
			ROUND(AVG(oord.review_score),2)
		FROM olist_order_items_dataset ooid
		JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id
		LEFT JOIN olist_order_reviews_dataset oord ON ooid.order_id = oord.order_id
		WHERE ooid.seller_id = p_id_vendedor
		AND ood.order_purchase_timestamp BETWEEN p_data_inicio AND p_data_fim;
END;
$$; -- Indicador de fim da função

-- Teste
SELECT ooid.seller_id FROM olist_order_items_dataset ooid;
SELECT * FROM sp_relatorio_vendedor(
    'dd7ddc04-e1b6-c2c6-1435-2b383efe2d36', 
    '2017-01-01 00:00:00', 
    '2018-12-31 23:59:59'
);

-- 2. Criar a procedure/function sp_relatorio_categoria(categoria, data_inicio, data_fim), que retorna 
	-- faturamento total e ticket médio da categoria de produto no período informado.
--> Extrai o relatório de performance da categoria buscada
CREATE OR REPLACE FUNCTION sp_relatorio_categoria(
	p_categoria VARCHAR(50), 
	p_data_inicio TIMESTAMP, 
	p_data_fim TIMESTAMP
)
RETURNS TABLE (
	categoria_pesquisada VARCHAR(50),
	faturamento_total NUMERIC,
	ticket_medio NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY
		SELECT
			p_categoria,
			SUM(ooid.price),
			ROUND(AVG(ooid.price),2)
		FROM olist_order_items_dataset ooid
		JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id
		JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id
		WHERE opd.product_category_name = p_categoria
		AND ood.order_purchase_timestamp BETWEEN p_data_inicio AND p_data_fim;
END;
$$;

-- Teste
SELECT DISTINCT product_category_name FROM olist_products_dataset;
SELECT * FROM sp_relatorio_categoria('pet_shop', '2017-01-01', '2018-01-01');
