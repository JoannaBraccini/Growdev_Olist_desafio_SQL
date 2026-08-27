-- Bloco E — CASE WHEN

-- 1. Classificar pedidos por prazo de entrega: "adiantado", "no prazo" ou "atrasado" (comparando data real x estimada).
--> Classifica os pedidos entregues em adiantado, no prazo ou atrasado, útil para avaliar a precisão das estimativas de entrega.
SELECT 
	order_id AS pedido,
	order_estimated_delivery_date AS data_estimada,
	order_delivered_customer_date AS data_entrega_real,
	CASE 
		WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'adiantado'
		WHEN order_delivered_customer_date = order_estimated_delivery_date THEN 'no prazo'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'atrasado'
		ELSE 'não entregue'
	END AS status_prazo
FROM olist_orders_dataset 
WHERE order_status = 'delivered'
ORDER BY data_entrega_real DESC;

-- 2. Classificar clientes por faixa de gasto total: "bronze", "prata", "ouro".
-- Agrupar os clientes por consumo acumulado é útil para estruturar réguas de marketing.
SELECT 
	gasto_clientes.cliente,
	gasto_clientes.gasto_total,
	CASE 
		WHEN gasto_clientes.gasto_total <= 1000 THEN 'bronze'
		WHEN gasto_clientes.gasto_total <= 5000 THEN 'prata'
		ELSE 'ouro'
	END as categoria_fidelidade
FROM (
	-- Subquery: somatório de pagamentos por cliente
	SELECT 
		ocd.customer_unique_id AS cliente,
		SUM(oopd.payment_value) AS gasto_total
	FROM olist_customers_dataset ocd
	JOIN olist_orders_dataset ood ON ocd.customer_id = ood.customer_id 
	JOIN olist_order_payments_dataset oopd ON ood.order_id = oopd.order_id 
	GROUP BY cliente
) gasto_clientes
ORDER BY gasto_total DESC;

-- 3. Classificar produtos por faixa de peso: "leve", "médio", "pesado" (com base em product_weight_g).
--> Categorizar as mercadorias por faixas de peso é útil para definir agrupamentos logísticos e restrições de manuseio.
SELECT 
	product_id AS produto,
    product_category_name AS categoria,
    product_weight_g AS peso_gramas,
	CASE 
		WHEN product_weight_g <= 1000 THEN 'leve'
		WHEN product_weight_g <= 5000 THEN 'médio'
		WHEN product_weight_g > 5000 THEN 'pesado'
		ELSE 'Sem peso cadastrado'
	END AS classificacao_peso
FROM olist_products_dataset
ORDER BY product_weight_g DESC;

-- 4. Classificar pagamentos como "à vista" ou "parcelado", e dentro de parcelado sinalizar parcelamentos longos 
	-- (payment_installments > 6).
--> Segmenta as transações, possibilitando identificar dependências de crédito e riscos para financiamento a longo prazo.
SELECT 
	order_id AS pedido,
    payment_type AS forma_pgto,
    payment_installments AS parcelas,
    payment_value AS valor,
	CASE 
		WHEN payment_installments > 6 THEN 'parcelamento longo'
		WHEN payment_installments > 1 THEN 'parcelado'
		WHEN payment_installments = 1 THEN 'à vista'
		ELSE 'Não Definido'
	END AS tipo_parcelamento
FROM olist_order_payments_dataset 
ORDER BY parcelas DESC;
