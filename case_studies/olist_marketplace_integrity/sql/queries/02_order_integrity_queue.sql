SELECT
    order_id,
    customer_state,
    seller_states,
    categories,
    order_status,
    order_purchase_timestamp,
    delivered_customer_date,
    estimated_delivery_date,
    item_count,
    seller_count,
    total_item_value,
    total_freight_value,
    total_payment_value,
    max_payment_installments,
    min_review_score,
    priority_score,
    priority_band,
    risk_flags
FROM v_order_integrity_queue
ORDER BY priority_score DESC, order_purchase_timestamp DESC
LIMIT 100;

