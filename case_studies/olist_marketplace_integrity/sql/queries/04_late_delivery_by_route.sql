SELECT
    customer_state,
    seller_state,
    COUNT(*) AS order_count,
    SUM(CASE WHEN delivered_late_flag = 1 THEN 1 ELSE 0 END) AS late_delivery_count,
    ROUND(AVG(CASE WHEN delivered_late_flag = 1 THEN days_late ELSE NULL END), 1) AS avg_days_late_when_late,
    ROUND(1.0 * SUM(CASE WHEN delivered_late_flag = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS late_delivery_rate,
    ROUND(AVG(min_review_score), 2) AS avg_review_score
FROM v_order_features
WHERE delivered_customer_date IS NOT NULL
  AND seller_count = 1
  AND seller_state IS NOT NULL
GROUP BY customer_state, seller_state
HAVING COUNT(*) >= 30
ORDER BY late_delivery_rate DESC, order_count DESC
LIMIT 100;

