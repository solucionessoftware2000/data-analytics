-- Share of sellers located in São Paulo and in the Southeast, among sellers with sales in the period
WITH sellers AS (
    SELECT DISTINCT
        seller_id,
        seller_state
    FROM items
    WHERE purchase_date >= :start
      AND purchase_date < :end
)
SELECT
    COUNT(*) AS sellers,
    100.0 * AVG(seller_state = 'SP') AS sellers_in_sao_paulo_pct,
    100.0 * AVG(seller_state IN ('ES', 'MG', 'RJ', 'SP')) AS sellers_in_southeast_pct
FROM sellers;
