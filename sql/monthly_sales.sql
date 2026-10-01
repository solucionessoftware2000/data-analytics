-- Monthly sales indicators: orders, units, revenue, average ticket and distinct customers
SELECT
    strftime('%Y-%m-01', purchase_date) AS month,
    COUNT(*) AS orders,
    SUM(units) AS units,
    SUM(revenue) AS revenue,
    AVG(revenue) AS avg_ticket,
    COUNT(DISTINCT customer_unique_id) AS customers
FROM orders
WHERE purchase_date >= :start
  AND purchase_date < :end
GROUP BY month
ORDER BY month;
