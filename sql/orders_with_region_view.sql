-- View that adds the Brazilian region of the customer's state to every order
DROP VIEW IF EXISTS orders_with_region;

CREATE VIEW orders_with_region AS
SELECT
    *,
    CASE
        WHEN customer_state IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO') THEN 'North'
        WHEN customer_state IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Northeast'
        WHEN customer_state IN ('DF', 'GO', 'MT', 'MS') THEN 'Central-West'
        WHEN customer_state IN ('ES', 'MG', 'RJ', 'SP') THEN 'Southeast'
        WHEN customer_state IN ('PR', 'RS', 'SC') THEN 'South'
    END AS region
FROM orders;
