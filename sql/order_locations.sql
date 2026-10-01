-- Location of every order, from the customer's zip code prefix, for the customer map
SELECT
    o.order_id,
    o.customer_state,
    g.lat,
    g.lng
FROM orders AS o
JOIN geolocation AS g
    ON g.zip_prefix = o.customer_zip_prefix
WHERE o.purchase_date >= :start
  AND o.purchase_date < :end;
