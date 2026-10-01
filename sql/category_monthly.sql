-- Units and revenue by category and month, including zeros for months without sales.
-- A recursive CTE builds the calendar of months, which is crossed with every category.
WITH RECURSIVE months(month) AS (
    SELECT :first_month
    UNION ALL
    SELECT date(month, '+1 month')
    FROM months
    WHERE month < :last_month
),
categories AS (
    SELECT DISTINCT category
    FROM items
    WHERE purchase_date >= :start
      AND purchase_date < :end
),
sales AS (
    SELECT
        strftime('%Y-%m-01', purchase_date) AS month,
        category,
        COUNT(*) AS units,
        SUM(price) AS revenue
    FROM items
    WHERE purchase_date >= :start
      AND purchase_date < :end
    GROUP BY month, category
)
SELECT
    m.month,
    c.category,
    COALESCE(s.units, 0) AS units,
    COALESCE(s.revenue, 0) AS revenue
FROM months AS m
CROSS JOIN categories AS c
LEFT JOIN sales AS s
    ON s.month = m.month
   AND s.category = c.category
ORDER BY m.month, c.category;
