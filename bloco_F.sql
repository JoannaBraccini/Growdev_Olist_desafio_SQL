-- Bloco F — CTE / tabela temporária

-- 1. Construir uma CTE de faturamento mensal por estado e, a partir dela, calcular a variação percentual de um mês para o outro.
--> Mostra a taxa de crescimento ou retração da receita mensal por estado, útil para identificar sazonalidade regional e mercados em expansão.

-- CTE inicial com o faturamento de todos os meses e estados
WITH faturamento_mensal AS (
    SELECT 
        ocd.customer_state AS estado,
        EXTRACT(YEAR FROM ood.order_purchase_timestamp) AS ano,
        EXTRACT(MONTH FROM ood.order_purchase_timestamp) AS mes,
        SUM(oopd.payment_value) AS faturamento_atual
    FROM olist_customers_dataset ocd 
    JOIN olist_orders_dataset ood ON ocd.customer_id = ood.customer_id
    JOIN olist_order_payments_dataset oopd ON ood.order_id = oopd.order_id
    WHERE ood.order_status = 'delivered'
    GROUP BY ocd.customer_state, 
    EXTRACT(YEAR FROM ood.order_purchase_timestamp), 
    EXTRACT(MONTH FROM ood.order_purchase_timestamp)
)
-- Query principal: join da CTE com ela mesma para comparar mês atual e anterior
SELECT 
	atual.estado,
	anterior.mes AS mes_anterior,
    anterior.faturamento_atual AS faturamento_anterior,
    atual.mes AS mes_atual,
    atual.faturamento_atual AS faturamento_atual,
    -- porcentagem: ((atual - anterior) / anterior) * 100
	ROUND(((atual.faturamento_atual - anterior.faturamento_atual) / anterior.faturamento_atual) * 100, 2) AS variacao_pct
FROM faturamento_mensal atual
-- conectar o mesmo estado, no mesmo ano, onde o mês anterior é igual ao mês atual menos 1
JOIN faturamento_mensal anterior ON atual.estado = anterior.estado 
  AND (
    -- Regra 1: se fevereiro a dezembro do mesmo ano
    (atual.ano = anterior.ano AND anterior.mes = atual.mes - 1)
    OR 
    -- Regra 2: se janeiro (virada de ano)
    (atual.mes = 1 AND anterior.ano = atual.ano - 1 AND anterior.mes = 12)
  )
ORDER BY atual.estado, atual.ano, atual.mes;
-- Erro encontrado: mes_anterior não tem mês 12 e mes_atual não tem mês 1.
	-- Solução: se mês atual > 1 -> busca anos iguais e mês anterior -1, senão ano atual -1 e mês 12

-- 2. Construir uma CTE com volume de avaliações e nota média por categoria de produto, 
	-- usada para identificar as categorias com pior reputação (nota média mais baixa e volume relevante de avaliações).
--> Identificar quais categorias com maior venda estão gerando maior insatisfação nos clientes.

-- CTE inicial com número de avaliações e nota média de cada categoria
WITH reputacao_categorias AS (
	SELECT 
		COALESCE(opd.product_category_name, pcnt.product_category_name_english, 'sem_categoria') AS categoria,
		COUNT(oord.review_id) AS qtd_avaliacoes,
		ROUND(AVG(oord.review_score),2) AS nota_media 
	FROM olist_products_dataset opd 
	LEFT JOIN olist_order_items_dataset ooid ON opd.product_id = ooid.product_id 
	LEFT JOIN olist_order_reviews_dataset oord ON ooid.order_id = oord.order_id
	LEFT JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name 
	WHERE ooid.product_id IS NOT NULL
	GROUP BY pcnt.product_category_name_english, opd.product_category_name
)
-- Query principal: filtra os resultados
SELECT 	
	categoria,
	qtd_avaliacoes,
	nota_media
FROM reputacao_categorias
WHERE qtd_avaliacoes > 50
ORDER BY nota_media ASC;
-- Erro encontrado: quantidade de 'sem categoria' muito alta.
	-- Solução: usar Left join para não perder as categorias que seriam deletadas no Inner join, excluir produtos sem uuid.
	-- Ainda teremos 1439 avaliações sem categoria, mas isso pode ser corrigido pois os produtos relacionados têm uuid e
	-- podem ser categorizados manualmente.
-- Teste para entender os null
SELECT 
    ood.order_id AS codigo_pedido,
    ood.order_status AS status_pedido,
    ooid.product_id AS codigo_produto,
    opd.product_category_name AS categoria_na_tabela_produtos,
    pcnt.product_category_name_english AS categoria_traduzida,
    oord.review_id AS codigo_avaliacao,
    oord.review_score AS nota
FROM olist_order_reviews_dataset oord
LEFT JOIN olist_order_items_dataset ooid ON oord.order_id = ooid.order_id 
LEFT JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id 
LEFT JOIN olist_orders_dataset ood ON oord.order_id = ood.order_id
LEFT JOIN product_category_name_translation pcnt ON pcnt.product_category_name = opd.product_category_name 
WHERE opd.product_category_name IS NULL OR pcnt.product_category_name_english IS NULL -- Filtrar apenas o que ficou sem categoria
LIMIT 50;

-- 3. Construir uma CTE de frete médio por estado do cliente, usada para comparar cada estado com a média geral de frete.
--> Avalia o custo logístico regional comparando o frete médio de cada estado com a média nacional.

-- CTE inicial com valor médio de frete e estado dos clientes
WITH media_fretes AS (
	SELECT 
		ocd.customer_state AS estado,
		ROUND(AVG(ooid.freight_value),2) AS frete_medio,
		-- Subquery isolada calculando a média nacional
		(SELECT ROUND(AVG(freight_value), 2) FROM olist_order_items_dataset) AS media_geral
	FROM olist_order_items_dataset ooid 
	JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id 
	JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id 
	GROUP BY estado
)
-- Query principal fazendo a comparação entre os fretes
SELECT 
	media.estado,
	media.frete_medio,
	media.media_geral,
	-- Quanto o estado está acima ou abaixo da média nacional
	ROUND(media.frete_medio - media.media_geral, 2) AS diferenca
FROM media_fretes media
ORDER BY media.frete_medio DESC;
