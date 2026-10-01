-- Customer and seller coordinates for every item sold, to measure shipping distances.
-- The geolocation table is joined twice: once for the customer's zip code prefix
-- and once for the seller's.
SELECT
    i.order_id,
    o.customer_state,
    customer_geo.lat AS customer_lat,
    customer_geo.lng AS customer_lng,
    seller_geo.lat AS seller_lat,
    seller_geo.lng AS seller_lng
FROM items AS i
JOIN orders AS o
    ON o.order_id = i.order_id
JOIN geolocation AS customer_geo
    ON customer_geo.zip_prefix = o.customer_zip_prefix
JOIN geolocation AS seller_geo
    ON seller_geo.zip_prefix = i.seller_zip_prefix
WHERE o.purchase_date >= :start
  AND o.purchase_date < :end;
