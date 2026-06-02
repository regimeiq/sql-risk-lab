SELECT
    customer_state,
    categories,
    order_status,
    COUNT(*) AS order_count,
    SUM(CASE WHEN low_review_flag = 1 THEN 1 ELSE 0 END) AS low_review_count,
    ROUND(1.0 * SUM(CASE WHEN low_review_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS low_review_rate,
    ROUND(AVG(days_late), 1) AS avg_days_late,
    ROUND(AVG(total_item_value), 2) AS avg_item_value
FROM v_order_features
WHERE min_review_score IS NOT NULL
GROUP BY customer_state, categories, order_status
HAVING COUNT(*) >= 25
ORDER BY low_review_rate DESC, order_count DESC
LIMIT 100;

