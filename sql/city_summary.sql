-- Customers, orders and revenue by city, with the city's approximate location
-- (the average coordinates of its orders) and its share of the state's customers
WITH city_orders AS (
    SELECT
        o.customer_city,
        o.customer_state,
        o.customer_unique_id,
        o.revenue,
        g.lat,
        g.lng
    FROM orders AS o
    LEFT JOIN geolocation AS g
        ON g.zip_prefix = o.customer_zip_prefix
    WHERE o.purchase_date >= :start
      AND o.purchase_date < :end
),
cities AS (
    SELECT
        customer_city,
        customer_state,
        COUNT(DISTINCT customer_unique_id) AS customers,
        COUNT(*) AS orders,
        SUM(revenue) AS revenue,
        AVG(lat) AS lat,
        AVG(lng) AS lng
    FROM city_orders
    GROUP BY customer_city, customer_state
)
SELECT
    *,
    100.0 * customers / SUM(customers) OVER (PARTITION BY customer_state) AS share_of_state_customers_pct
FROM cities
ORDER BY customers DESC;
