-- Orders, revenue, average ticket and share of revenue by customer state
SELECT
    customer_state,
    region,
    COUNT(*) AS orders,
    SUM(revenue) AS revenue,
    AVG(revenue) AS avg_ticket,
    100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER () AS revenue_pct
FROM orders_with_region
WHERE purchase_date >= :start
  AND purchase_date < :end
GROUP BY customer_state, region
ORDER BY revenue DESC;
