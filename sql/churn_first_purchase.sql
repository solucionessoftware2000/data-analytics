-- One row per customer describing their first purchase occasion, plus the day of their
-- second purchase occasion, if there was one.
-- A purchase occasion is a day on which the customer placed at least one order: several
-- orders placed on the same day are one purchase split across sellers, not a return.
WITH occasion_orders AS (
    SELECT
        o.*,
        date(o.purchase_date) AS purchase_day,
        -- Category and payment method of the order with the highest revenue on that day
        FIRST_VALUE(o.main_category) OVER same_day AS occasion_main_category,
        FIRST_VALUE(o.payment_type) OVER same_day AS occasion_payment_type
    FROM orders_with_region AS o
    WINDOW same_day AS (
        PARTITION BY o.customer_unique_id, date(o.purchase_date)
        ORDER BY o.revenue DESC, o.order_id
    )
),
occasions AS (
    SELECT
        customer_unique_id,
        purchase_day,
        MIN(customer_state) AS customer_state,
        MIN(region) AS region,
        MIN(occasion_main_category) AS main_category,
        MIN(occasion_payment_type) AS payment_type,
        COUNT(*) AS orders,
        SUM(units) AS units,
        SUM(revenue) AS revenue,
        SUM(freight_value) AS freight_value,
        MAX(installments) AS installments,
        MAX(delivery_days) AS delivery_days,
        MAX(delay_days) AS delay_days,
        MAX(is_late) AS is_late,
        AVG(review_score) AS review_score,
        MAX(has_comment) AS has_comment,
        MAX(delivered_date) AS delivered_date,
        MAX(review_date) AS review_date
    FROM occasion_orders
    GROUP BY customer_unique_id, purchase_day
),
numbered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_day) AS occasion_number
    FROM occasions
)
SELECT
    first_occasion.*,
    -- Prediction moment: when the first occasion has been delivered and, if reviewed, reviewed
    max(first_occasion.delivered_date,
        COALESCE(first_occasion.review_date, first_occasion.delivered_date)) AS prediction_date,
    second_occasion.purchase_day AS second_purchase_day
FROM numbered AS first_occasion
LEFT JOIN numbered AS second_occasion
    ON second_occasion.customer_unique_id = first_occasion.customer_unique_id
   AND second_occasion.occasion_number = 2
WHERE first_occasion.occasion_number = 1;
