-- Categories ranked by revenue and by units, with each category's share and cumulative share of revenue
WITH category_sales AS (
    SELECT
        category,
        SUM(price) AS revenue,
        COUNT(*) AS units,
        COUNT(DISTINCT product_id) AS products,
        AVG(price) AS avg_price
    FROM items
    WHERE purchase_date >= :start
      AND purchase_date < :end
    GROUP BY category
)
SELECT
    category,
    revenue,
    units,
    products,
    avg_price,
    100.0 * revenue / SUM(revenue) OVER () AS revenue_pct,
    100.0 * SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING)
        / SUM(revenue) OVER () AS cumulative_pct,
    RANK() OVER (ORDER BY revenue DESC) AS rank_by_revenue,
    RANK() OVER (ORDER BY units DESC) AS rank_by_units
FROM category_sales
ORDER BY revenue DESC;
