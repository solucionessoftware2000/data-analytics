-- Share of orders that contain a single distinct product
SELECT
    100.0 * AVG(distinct_products = 1) AS single_product_pct
FROM (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS distinct_products
    FROM items
    WHERE purchase_date >= :start
      AND purchase_date < :end
    GROUP BY order_id
);
