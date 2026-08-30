-- Bloco I — Window functions

-- 1. Ranking (RANK()) dos vendedores por faturamento dentro de cada estado.
--> Identificar a liderança de mercado regional e a concentração de vendas por estado.
WITH faturamento_vendedores AS(
	SELECT 
		osd.seller_state AS estado,
		osd.seller_id AS vendedor,
		SUM(ooid.price) AS faturamento
	FROM olist_sellers_dataset osd 
	JOIN olist_order_items_dataset ooid ON osd.seller_id = ooid.seller_id 
	GROUP BY estado, vendedor 
)
SELECT 
    estado,
    vendedor,
    faturamento,
    DENSE_RANK() OVER(
    PARTITION BY estado 
    ORDER BY faturamento DESC
) AS ranking
FROM faturamento_vendedores
ORDER BY estado, ranking;

-- Erro observado: linhas 122 e 123 com empate com a mesma posição (35) e a linha 124 recebe rank 37.
	-- Solução: usar dense_rank no lugar de rank, ele remove o salto de posição, porém não remove o empate.

-- 2. Faturamento mensal acumulado (SUM(...) OVER (ORDER BY ...)) por vendedor.
--> Acompanhar o crescimento histórico dos parceiros e identificar a evolução de cada vendedor.
WITH faturamento_mensal AS(
	SELECT 
		ooid.seller_id AS vendedor,
		TO_CHAR(ood.order_purchase_timestamp, 'YYYY-MM') AS ano_mes,
		SUM(ooid.price) AS faturamento_mensal 
	FROM olist_order_items_dataset ooid
	JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id 
	GROUP BY vendedor, ano_mes 
)
SELECT 
	vendedor,
	ano_mes,
	faturamento_mensal,
	SUM(faturamento_mensal) OVER(
		PARTITION BY vendedor 
		ORDER BY ano_mes ASC
	) AS faturamento_acumulado
FROM faturamento_mensal 
ORDER BY vendedor, ano_mes;

-- 3. Percentual de participação de cada vendedor no faturamento total do seu estado (SUM(...) OVER (PARTITION BY estado)).
--> Calcula a participação de mercado de cada vendedor.
WITH faturamento_total AS(
	SELECT 
		osd.seller_id AS vendedor,
		osd.seller_state AS estado,
		SUM(ooid.price) AS faturamento_vendedor
	FROM olist_order_items_dataset ooid
	JOIN olist_sellers_dataset osd ON ooid.seller_id = osd.seller_id
	GROUP BY vendedor, estado 
)
SELECT 
	vendedor,
	estado,
	faturamento_vendedor,
	-- Percentual de participação de cada vendedor:
	ROUND(
        (faturamento_vendedor / SUM(faturamento_vendedor) OVER(PARTITION BY estado)) * 100, 
        2
	) AS participacao_pct
FROM faturamento_total 
ORDER BY estado, faturamento_vendedor DESC;

-- 4. Variação de faturamento de um mês para o outro por vendedor, usando LAG().
--> Mostra a velocidade de crescimento de cada vendedor.
WITH faturamento_mensal_vendedores AS(
	SELECT 
		ooid.seller_id AS vendedor,
		TO_CHAR(ood.order_purchase_timestamp, 'YYYY-MM') AS ano_mes,
		SUM(ooid.price) AS faturamento_mensal 
	FROM olist_order_items_dataset ooid
	JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id 
	GROUP BY vendedor, ano_mes 
)
SELECT 
	vendedor,
	ano_mes,
	faturamento_mensal,
	LAG(faturamento_mensal) OVER(PARTITION BY vendedor ORDER BY ano_mes ASC) AS faturamento_anterior,
	-- Percentual: ROUND(((Atual - Anterior) / Anterior) * 100, 2)
	ROUND(
		((faturamento_mensal - LAG(faturamento_mensal) OVER(PARTITION BY vendedor ORDER BY ano_mes ASC))
		/ LAG(faturamento_mensal) OVER(PARTITION BY vendedor ORDER BY ano_mes ASC)) * 100,
		2
	) AS variacao_pct
FROM faturamento_mensal_vendedores 
ORDER BY vendedor, ano_mes;
