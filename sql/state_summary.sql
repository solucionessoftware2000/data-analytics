-- Demand and service indicators by customer state: customers, orders, revenue,
-- average freight, share of late deliveries and median delivery days.
-- The median is computed with window functions because SQLite has no MEDIAN function.
WITH period_orders AS (
    SELECT *
    FROM orders_with_region
    WHERE purchase_date >= :start
      AND purchase_date < :end
),
ranked AS (
    SELECT
        customer_state,
        delivery_days,
        ROW_NUMBER() OVER (PARTITION BY customer_state ORDER BY delivery_days) AS position,
        COUNT(*) OVER (PARTITION BY customer_state) AS state_orders
    FROM period_orders
),
medians AS (
    SELECT
        customer_state,
        AVG(delivery_days) AS median_delivery_days
    FROM ranked
    WHERE position IN ((state_orders + 1) / 2, (state_orders + 2) / 2)
    GROUP BY customer_state
)
SELECT
    p.customer_state,
    p.region,
    COUNT(DISTINCT p.customer_unique_id) AS customers,
    COUNT(*) AS orders,
    SUM(p.revenue) AS revenue,
    AVG(p.revenue) AS avg_ticket,
    AVG(p.freight_value) AS avg_freight,
    100.0 * AVG(p.is_late) AS late_pct,
    m.median_delivery_days
FROM period_orders AS p
JOIN medians AS m
    ON m.customer_state = p.customer_state
GROUP BY p.customer_state, p.region
ORDER BY customers DESC;
