SELECT
    category,
    COUNT(*) AS order_count,
    SUM(CASE WHEN delivered_late_flag = 1 THEN 1 ELSE 0 END) AS late_delivery_count,
    SUM(CASE WHEN canceled_or_unavailable_flag = 1 THEN 1 ELSE 0 END) AS canceled_or_unavailable_count,
    SUM(CASE WHEN low_review_flag = 1 THEN 1 ELSE 0 END) AS low_review_count,
    ROUND(1.0 * SUM(CASE WHEN delivered_late_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS late_delivery_rate,
    ROUND(1.0 * SUM(CASE WHEN low_review_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS low_review_rate,
    ROUND(AVG(total_item_value), 2) AS avg_item_value
FROM v_order_category_features
GROUP BY category
HAVING COUNT(*) >= 100
ORDER BY low_review_rate DESC, late_delivery_rate DESC, order_count DESC
LIMIT 100;

