-- Units sold between two dates (the end date is excluded)
SELECT
    COUNT(*) AS units
FROM items
WHERE purchase_date >= :start
  AND purchase_date < :end;
