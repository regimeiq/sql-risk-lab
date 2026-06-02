SELECT
    payment_types,
    max_payment_installments,
    COUNT(*) AS order_count,
    ROUND(AVG(total_payment_value), 2) AS avg_payment_value,
    ROUND(AVG(total_item_value), 2) AS avg_item_value,
    ROUND(AVG(min_review_score), 2) AS avg_review_score,
    SUM(CASE WHEN canceled_or_unavailable_flag = 1 THEN 1 ELSE 0 END) AS canceled_or_unavailable_count,
    SUM(CASE WHEN low_review_flag = 1 THEN 1 ELSE 0 END) AS low_review_count
FROM v_order_features
WHERE payment_types IS NOT NULL
GROUP BY payment_types, max_payment_installments
HAVING COUNT(*) >= 25
ORDER BY max_payment_installments DESC, avg_payment_value DESC
LIMIT 100;

