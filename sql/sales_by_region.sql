-- Sales, average ticket, freight, delivery time and late deliveries by region.
-- SQLite has no MEDIAN function, so the median delivery time is computed with window functions:
-- we number each region's orders by delivery time and average the one or two middle positions.
WITH period_orders AS (
    SELECT *
    FROM orders_with_region
    WHERE purchase_date >= :start
      AND purchase_date < :end
),
ranked AS (
    SELECT
        region,
        delivery_days,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY delivery_days) AS position,
        COUNT(*) OVER (PARTITION BY region) AS region_orders
    FROM period_orders
),
medians AS (
    SELECT
        region,
        AVG(delivery_days) AS median_delivery_days
    FROM ranked
    WHERE position IN ((region_orders + 1) / 2, (region_orders + 2) / 2)
    GROUP BY region
)
SELECT
    p.region,
    COUNT(*) AS orders,
    SUM(p.revenue) AS revenue,
    AVG(p.revenue) AS avg_ticket,
    AVG(p.freight_value) AS avg_freight,
    m.median_delivery_days,
    100.0 * AVG(p.is_late) AS late_pct,
    100.0 * SUM(p.revenue) / (SELECT SUM(revenue) FROM period_orders) AS revenue_pct
FROM period_orders AS p
JOIN medians AS m
    ON m.region = p.region
GROUP BY p.region
ORDER BY revenue DESC;
