-- Share of orders and revenue by hour of purchase
WITH hourly AS (
    SELECT
        CAST(strftime('%H', purchase_date) AS INTEGER) AS hour,
        COUNT(*) AS orders,
        SUM(revenue) AS revenue
    FROM orders
    WHERE purchase_date >= :start
      AND purchase_date < :end
    GROUP BY hour
)
SELECT
    hour,
    orders,
    revenue,
    100.0 * orders / SUM(orders) OVER () AS orders_pct,
    100.0 * revenue / SUM(revenue) OVER () AS revenue_pct
FROM hourly
ORDER BY hour;
