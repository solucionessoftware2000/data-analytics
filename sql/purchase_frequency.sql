-- Orders and purchase occasions (distinct purchase days) of every customer
SELECT
    customer_unique_id,
    COUNT(*) AS orders,
    COUNT(DISTINCT date(purchase_date)) AS purchase_occasions
FROM orders
GROUP BY customer_unique_id;
