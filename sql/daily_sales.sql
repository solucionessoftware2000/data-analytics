-- Orders and revenue per purchase day
SELECT
    date(purchase_date) AS day,
    COUNT(*) AS orders,
    SUM(revenue) AS revenue
FROM orders
WHERE purchase_date >= :start
  AND purchase_date < :end
GROUP BY day
ORDER BY day;
