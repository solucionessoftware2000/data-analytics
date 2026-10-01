-- Share of orders by main payment method
SELECT
    payment_type,
    COUNT(*) AS orders,
    100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS orders_pct
FROM orders
WHERE purchase_date >= :start
  AND purchase_date < :end
  AND payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY orders DESC;
