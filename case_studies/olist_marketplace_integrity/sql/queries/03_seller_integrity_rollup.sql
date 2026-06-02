SELECT
    seller_id,
    seller_state,
    order_count,
    delivered_order_count,
    canceled_or_unavailable_count,
    late_delivery_count,
    very_late_count,
    low_review_count,
    total_item_value,
    avg_review_score,
    late_delivery_rate,
    low_review_rate,
    cancellation_rate,
    seller_priority_score,
    seller_priority_band
FROM v_seller_integrity_rollup
WHERE order_count >= 20
ORDER BY seller_priority_score DESC, order_count DESC
LIMIT 100;

