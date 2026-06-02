DROP VIEW IF EXISTS v_order_category_features;
DROP VIEW IF EXISTS v_seller_integrity_rollup;
DROP VIEW IF EXISTS v_order_integrity_queue;
DROP VIEW IF EXISTS v_order_features;
DROP VIEW IF EXISTS v_review_rollup;
DROP VIEW IF EXISTS v_payment_rollup;
DROP VIEW IF EXISTS v_order_item_rollup;

CREATE VIEW v_order_item_rollup AS
SELECT
    oi.order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT oi.seller_id) AS seller_count,
    GROUP_CONCAT(DISTINCT oi.seller_id) AS seller_ids,
    GROUP_CONCAT(DISTINCT s.seller_state) AS seller_states,
    CASE
        WHEN COUNT(DISTINCT s.seller_state) = 1 THEN MAX(s.seller_state)
        ELSE NULL
    END AS seller_state,
    GROUP_CONCAT(DISTINCT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown')) AS categories,
    SUM(CAST(oi.price AS REAL)) AS total_item_value,
    SUM(CAST(oi.freight_value AS REAL)) AS total_freight_value
FROM order_items oi
LEFT JOIN sellers s
  ON s.seller_id = oi.seller_id
LEFT JOIN products p
  ON p.product_id = oi.product_id
LEFT JOIN product_category_translation t
  ON t.product_category_name = p.product_category_name
GROUP BY oi.order_id;

CREATE VIEW v_payment_rollup AS
SELECT
    order_id,
    COUNT(*) AS payment_count,
    GROUP_CONCAT(DISTINCT payment_type) AS payment_types,
    MAX(CAST(payment_installments AS INTEGER)) AS max_payment_installments,
    SUM(CAST(payment_value AS REAL)) AS total_payment_value
FROM order_payments
GROUP BY order_id;

CREATE VIEW v_review_rollup AS
SELECT
    order_id,
    COUNT(*) AS review_count,
    MIN(CAST(review_score AS INTEGER)) AS min_review_score,
    AVG(CAST(review_score AS REAL)) AS avg_review_score,
    MAX(
        CASE
            WHEN review_comment_title IS NOT NULL OR review_comment_message IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS has_review_comment
FROM order_reviews
GROUP BY order_id;

CREATE VIEW v_order_features AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date AS delivered_customer_date,
    o.order_estimated_delivery_date AS estimated_delivery_date,
    item.item_count,
    item.seller_count,
    item.seller_ids,
    item.seller_states,
    item.seller_state,
    COALESCE(item.categories, 'unknown') AS categories,
    item.total_item_value,
    item.total_freight_value,
    ROUND(item.total_freight_value / NULLIF(item.total_item_value, 0), 3) AS freight_to_item_ratio,
    pay.payment_count,
    pay.payment_types,
    pay.max_payment_installments,
    pay.total_payment_value,
    review.review_count,
    review.min_review_score,
    review.avg_review_score,
    review.has_review_comment,
    ROUND(JULIANDAY(o.order_approved_at) - JULIANDAY(o.order_purchase_timestamp), 1) AS approval_delay_days,
    ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp), 1) AS delivery_days,
    ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date), 1) AS days_late,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND JULIANDAY(o.order_delivered_customer_date) > JULIANDAY(o.order_estimated_delivery_date)
        THEN 1 ELSE 0
    END AS delivered_late_flag,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date) >= 7
        THEN 1 ELSE 0
    END AS very_late_flag,
    CASE
        WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 ELSE 0
    END AS canceled_or_unavailable_flag,
    CASE
        WHEN review.min_review_score <= 2 THEN 1 ELSE 0
    END AS low_review_flag,
    CASE
        WHEN pay.max_payment_installments >= 10 THEN 1 ELSE 0
    END AS high_installment_flag,
    CASE
        WHEN item.seller_count > 1 THEN 1 ELSE 0
    END AS multi_seller_flag,
    CASE
        WHEN item.total_freight_value / NULLIF(item.total_item_value, 0) >= 0.50 THEN 1 ELSE 0
    END AS high_freight_ratio_flag,
    CASE
        WHEN item.item_count >= 5 THEN 1 ELSE 0
    END AS high_item_count_flag,
    CASE
        WHEN item.total_item_value >= 1000 THEN 1 ELSE 0
    END AS high_value_flag
FROM orders o
JOIN customers c
  ON c.customer_id = o.customer_id
LEFT JOIN v_order_item_rollup item
  ON item.order_id = o.order_id
LEFT JOIN v_payment_rollup pay
  ON pay.order_id = o.order_id
LEFT JOIN v_review_rollup review
  ON review.order_id = o.order_id;

CREATE VIEW v_order_integrity_queue AS
WITH scored AS (
    SELECT
        ofe.*,
        (
            CASE WHEN canceled_or_unavailable_flag = 1 THEN 35 ELSE 0 END +
            CASE WHEN very_late_flag = 1 THEN 25 ELSE 0 END +
            CASE WHEN delivered_late_flag = 1 AND very_late_flag = 0 THEN 10 ELSE 0 END +
            CASE WHEN low_review_flag = 1 THEN 25 ELSE 0 END +
            CASE WHEN high_installment_flag = 1 THEN 10 ELSE 0 END +
            CASE WHEN high_freight_ratio_flag = 1 THEN 10 ELSE 0 END +
            CASE WHEN multi_seller_flag = 1 THEN 10 ELSE 0 END +
            CASE WHEN high_item_count_flag = 1 THEN 10 ELSE 0 END +
            CASE WHEN high_value_flag = 1 THEN 10 ELSE 0 END +
            CASE WHEN low_review_flag = 1 AND has_review_comment = 1 THEN 5 ELSE 0 END
        ) AS priority_score,
        TRIM(
            CASE WHEN canceled_or_unavailable_flag = 1 THEN 'canceled_or_unavailable|' ELSE '' END ||
            CASE WHEN very_late_flag = 1 THEN 'very_late_delivery|' ELSE '' END ||
            CASE WHEN delivered_late_flag = 1 AND very_late_flag = 0 THEN 'late_delivery|' ELSE '' END ||
            CASE WHEN low_review_flag = 1 THEN 'low_review_score|' ELSE '' END ||
            CASE WHEN high_installment_flag = 1 THEN 'high_installments|' ELSE '' END ||
            CASE WHEN high_freight_ratio_flag = 1 THEN 'high_freight_ratio|' ELSE '' END ||
            CASE WHEN multi_seller_flag = 1 THEN 'multi_seller_order|' ELSE '' END ||
            CASE WHEN high_item_count_flag = 1 THEN 'high_item_count|' ELSE '' END ||
            CASE WHEN high_value_flag = 1 THEN 'high_value_order|' ELSE '' END ||
            CASE WHEN low_review_flag = 1 AND has_review_comment = 1 THEN 'low_review_with_comment|' ELSE '' END,
            '|'
        ) AS risk_flags
    FROM v_order_features ofe
)
SELECT
    *,
    CASE
        WHEN priority_score >= 80 THEN 'Critical'
        WHEN priority_score >= 55 THEN 'High'
        WHEN priority_score >= 35 THEN 'Medium'
        ELSE 'Low'
    END AS priority_band
FROM scored
WHERE priority_score >= 35;

CREATE VIEW v_seller_integrity_rollup AS
WITH seller_orders AS (
    SELECT DISTINCT
        oi.seller_id,
        oi.order_id
    FROM order_items oi
),
seller_order_value AS (
    SELECT
        seller_id,
        order_id,
        SUM(CAST(price AS REAL)) AS seller_item_value,
        SUM(CAST(freight_value AS REAL)) AS seller_freight_value
    FROM order_items
    GROUP BY seller_id, order_id
),
base AS (
    SELECT
        so.seller_id,
        s.seller_state,
        COUNT(*) AS order_count,
        SUM(CASE WHEN ofe.order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_order_count,
        SUM(ofe.canceled_or_unavailable_flag) AS canceled_or_unavailable_count,
        SUM(ofe.delivered_late_flag) AS late_delivery_count,
        SUM(ofe.very_late_flag) AS very_late_count,
        SUM(ofe.low_review_flag) AS low_review_count,
        SUM(sov.seller_item_value) AS total_item_value,
        SUM(sov.seller_freight_value) AS total_freight_value,
        AVG(ofe.min_review_score) AS avg_review_score,
        ROUND(1.0 * SUM(ofe.delivered_late_flag) / COUNT(*), 3) AS late_delivery_rate,
        ROUND(1.0 * SUM(ofe.low_review_flag) / COUNT(*), 3) AS low_review_rate,
        ROUND(1.0 * SUM(ofe.canceled_or_unavailable_flag) / COUNT(*), 3) AS cancellation_rate
    FROM seller_orders so
    JOIN sellers s
      ON s.seller_id = so.seller_id
    JOIN v_order_features ofe
      ON ofe.order_id = so.order_id
    JOIN seller_order_value sov
      ON sov.seller_id = so.seller_id
     AND sov.order_id = so.order_id
    GROUP BY so.seller_id, s.seller_state
),
scored AS (
    SELECT
        *,
        (
            CASE WHEN late_delivery_rate >= 0.30 THEN 25 ELSE 0 END +
            CASE WHEN low_review_rate >= 0.20 THEN 25 ELSE 0 END +
            CASE WHEN cancellation_rate >= 0.05 THEN 20 ELSE 0 END +
            CASE WHEN very_late_count >= 10 THEN 15 ELSE 0 END +
            CASE WHEN order_count >= 100 AND low_review_rate >= 0.10 THEN 10 ELSE 0 END +
            CASE WHEN total_item_value >= 50000 AND late_delivery_rate >= 0.20 THEN 10 ELSE 0 END
        ) AS seller_priority_score
    FROM base
)
SELECT
    *,
    CASE
        WHEN seller_priority_score >= 60 THEN 'High'
        WHEN seller_priority_score >= 35 THEN 'Medium'
        ELSE 'Low'
    END AS seller_priority_band
FROM scored;

CREATE VIEW v_order_category_features AS
SELECT DISTINCT
    ofe.order_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
    ofe.customer_state,
    ofe.order_status,
    ofe.delivered_late_flag,
    ofe.very_late_flag,
    ofe.canceled_or_unavailable_flag,
    ofe.low_review_flag,
    ofe.days_late,
    ofe.total_item_value,
    ofe.min_review_score
FROM v_order_features ofe
JOIN order_items oi
  ON oi.order_id = ofe.order_id
LEFT JOIN products p
  ON p.product_id = oi.product_id
LEFT JOIN product_category_translation t
  ON t.product_category_name = p.product_category_name;
