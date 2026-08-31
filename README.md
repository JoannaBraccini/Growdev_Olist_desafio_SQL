# Desafio de Análise de Dados: E-commerce Brazilian Olist

## 📋 Sobre o Projeto
Este repositório contém a resolução do desafio técnico de modelagem e extração de inteligência de negócios utilizando o banco de dados de e-commerce da Olist (Kaggle). O objetivo principal foi estruturar consultas SQL (DQL) divididas em blocos de complexidade evolutiva (do básico ao intermediário avançado), gerando uma camada de visualização analítica para suporte à tomada de decisões estratégicas.

---

## 🛠️ Tecnologias Utilizadas
O projeto foi desenvolvido utilizando as seguintes tecnologias:
* **SGBD:** PostgreSQL (v18) — Motor de banco de dados relacional utilizado para armazenamento, conversão de dados e execução das queries.
* **Linguagem Procedural:** PL/pgSQL — Utilizada no desenvolvimento das funções parametrizadas (Stored Functions).
* **Ferramenta de Conectividade/IDE:** DBeaver Community Edition — Interface utilizada para gerenciamento do banco de dados, execução dos scripts e auditoria dos resultados.
* **Dataset Base:** Olist Brazilian E-Commerce Dataset (Kaggle).

---

## 🚀 Como Rodar o Projeto Localmente

Siga o passo a passo abaixo para replicar o banco de dados e executar as análises na sua máquina:

### 1. Pré-requisitos
Certifique-se de ter instalado no seu computador:
* [PostgreSQL](https://postgresql.org)
* [DBeaver Community](https://dbeaver.io)

### 2. Download dos Dados
1. Baixe os arquivos CSV originais diretamente no ([https://kaggle.com](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)).
2. Extraia os arquivos em uma pasta de sua preferência.

### 3. Configuração do Banco de Dados
1. Abra o **DBeaver** e conecte-se ao seu servidor local do PostgreSQL.
2. Crie um novo banco de dados:
   ```sql
   CREATE DATABASE nome_do_banco;
   ```
3. Com o banco selecionado, crie as tabelas base e realize a importação dos arquivos CSV extraídos (utilizando a ferramenta de importação nativa do DBeaver). *Dica: Garanta a conversão dos campos de chaves primárias e estrangeiras (`order_id`, `customer_id`, `seller_id`) para o tipo `UUID` conforme boas práticas de modelagem.*

### 4. Execução dos Scripts
Os scripts estão organizados por blocos de evolução lógica na pasta raiz. Para testá-los:
1. Abra a pasta do projeto no DBeaver.
2. Execute os arquivos na ordem sequencial desejada (`bloco_A.sql`, `bloco_B.sql`, etc.).

---

## Entregáveis
Conforme o edital, o projeto está estruturado com scripts comentados:

* 📂 **`bloco_A.sql`** — Consultas básicas de filtragem, ordenação e limites operacionais.
* 📂 **`bloco_B.sql`** — Cruzamento de dados (INNER e LEFT JOINs) e mapeamento demográfico.
* 📂 **`bloco_C.sql`** — Sumarização gerencial, volumetria e métricas de agrupamento.
* 📂 **`bloco_D.sql`** — Subqueries independentes, correlacionadas e filtros lógicos de existência.
* 📂 **`bloco_E.sql`** — Regras de negócio dinâmicas e categorização de portfólio (CASE WHEN).
* 📂 **`bloco_F.sql`** — Tabelas Expressas (CTEs) para cálculos temporais complexos.
* 📂 **`bloco_G.sql`** — Criação de Views (Vitrines de Dados) permanentes para ferramentas de BI.
* 📂 **`bloco_H.sql`** — Funções procedurais parametrizadas (PL/pgSQL) para auditoria sob demanda.
* 📂 **`bloco_I.sql`** — Window Functions (Funções de Janela) para análise de concorrência e ritmo de crescimento.

## Insights

Durante o processo de mineração e exploração dos dados foram identificados comportamentos críticos e inconsistências que moldaram a estratégia de desenvolvimento das queries:

### Pedidos com Pagamento Ausente
Na consolidação da tabela unificada de vendas (**Bloco G**), detectou-se que centenas de pedidos possuíam itens com preços válidos na tabela de itens, mas registravam **zero linhas de transação financeira** na tabela de pagamentos. 
* **Insight Técnico:** Para bloquear retornos `NULL` que distorceriam as somas financeiras, foi aplicada a função `COALESCE` com retorno padronizado para `0.00`. Isso garantiu que falhas de integração no banco original não quebrassem as queries analíticas.

### Grupo "Sem Categoria"
Ao analisar os produtos sem identificação de departamento (**Bloco F e G**), descobriu-se que o grupo `'sem_categoria'` registrava um volume anormalmente alto de avaliações (mais de 2.300 registros) com nota média `3.17`. A investigação revelou dois cenários:  
1. Pedidos com status `unavailable` ou `canceled` não geram itens na tabela física, resultando em dados de produto nulos.  
2. Clientes insatisfeitos com a falha logística avaliavam mal o carrinho inteiro, jogando o ruído logístico para o grupo sem categoria.
* **Solução Aplicada:** Implementou-se um filtro `WHERE ooid.product_id IS NOT NULL` nas consultas de reputação. Isso isolou os ruídos das avaliações de produtos reais que foram empacotados e despachados, trazendo as notas para a realidade comercial.

### Lógica de Transição Temporal na Virada de Ano
No cálculo do crescimento percentual mês a mês por estado (**Bloco F**), identificou-se que a conta matemática padrão baseada estritamente no ano corrente quebrava na virada de Dezembro para Janeiro (pois Janeiro tenta buscar o mês "zero" do mesmo ano).
* **Solução Aplicada:** Operador condicional duplo `OR` e parênteses de escopo no `JOIN` para atuar como um "se/senão" de calendário. Quando o mês atual aponta para Janeiro (Mês 1), o banco altera dinamicamente sua rota de busca, retornando uma pasta no calendário para capturar o ano anterior e travando o alvo obrigatoriamente no Mês 12 (Dezembro).

### Concentração de Crédito e Comportamento de Parcelamento
As consultas financeiras do **Bloco B e C** revelaram uma forte dependência da plataforma em relação a vendas de longo prazo. O uso do `GROUP BY` e do `HAVING` provou que clientes frequentemente realizam parcelamentos superiores a 6 vezes em categorias de alto valor agregado ou dividem uma única compra utilizando múltiplos métodos de pagamento (como voucher + cartão de crédito).

### Concentração Regional (Window Functions)
Utilizando as funções de janela no **Bloco I** mapeou-se a pulverização do ecossistema de vendas. Descobriu-se que determinados estados possuem uma disputa saudável e bem distribuída entre dezenas de lojistas, enquanto outras regiões operam em zona de risco operacional, onde um único vendedor detém mais de **15% de Market Share de faturamento** de todo o seu estado.
