-- ABC classification of products by revenue.
-- A product's class depends on the cumulative share of revenue *before* it:
-- class A up to 80%, class B up to 95%, class C for the rest.
-- Ties in revenue are broken by product_id so the result is always the same.
WITH product_sales AS (
    SELECT
        product_id,
        MIN(category) AS category,
        COUNT(*) AS units,
        COUNT(DISTINCT order_id) AS orders,
        SUM(price) AS revenue,
        AVG(price) AS avg_price,
        MIN(purchase_date) AS first_sale,
        MAX(purchase_date) AS last_sale
    FROM items
    WHERE purchase_date >= :start
      AND purchase_date < :end
    GROUP BY product_id
),
cumulative AS (
    SELECT
        *,
        100.0 * revenue / SUM(revenue) OVER () AS revenue_pct,
        100.0 * SUM(revenue) OVER (ORDER BY revenue DESC, product_id ROWS UNBOUNDED PRECEDING)
            / SUM(revenue) OVER () AS cumulative_pct
    FROM product_sales
)
SELECT
    *,
    CASE
        WHEN cumulative_pct - revenue_pct < 80 THEN 'A'
        WHEN cumulative_pct - revenue_pct < 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM cumulative
ORDER BY revenue DESC, product_id;
