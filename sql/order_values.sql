-- Value and size of each order, used for the ticket and units distributions
SELECT
    order_id,
    revenue,
    freight_value,
    total_value,
    units
FROM orders
WHERE purchase_date >= :start
  AND purchase_date < :end;
