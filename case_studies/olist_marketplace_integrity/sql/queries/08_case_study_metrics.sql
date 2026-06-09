SELECT 'orders_total' AS metric, COUNT(*) AS value FROM v_order_features
UNION ALL
SELECT 'queued_orders_medium_plus', COUNT(*) FROM v_order_integrity_queue
UNION ALL
SELECT 'queued_orders_critical', COUNT(*) FROM v_order_integrity_queue WHERE priority_band = 'Critical'
UNION ALL
SELECT 'queued_orders_high', COUNT(*) FROM v_order_integrity_queue WHERE priority_band = 'High'
UNION ALL
SELECT 'queued_orders_medium', COUNT(*) FROM v_order_integrity_queue WHERE priority_band = 'Medium'
UNION ALL
SELECT 'queued_orders_low_review', COUNT(*) FROM v_order_integrity_queue WHERE risk_flags LIKE '%low_review_score%'
UNION ALL
SELECT 'queued_orders_canceled_or_unavailable', COUNT(*) FROM v_order_integrity_queue WHERE risk_flags LIKE '%canceled_or_unavailable%'
UNION ALL
SELECT 'queued_orders_very_late_delivery', COUNT(*) FROM v_order_integrity_queue WHERE risk_flags LIKE '%very_late_delivery%'
UNION ALL
SELECT 'queued_orders_high_installments', COUNT(*) FROM v_order_integrity_queue WHERE risk_flags LIKE '%high_installments%'
UNION ALL
SELECT 'sellers_total', COUNT(*) FROM v_seller_integrity_rollup
UNION ALL
-- Seller band metrics apply the same order_count >= 20 reporting floor as
-- 03_seller_integrity_rollup.sql, so these counts match the published rollup.
SELECT 'sellers_with_20plus_orders', COUNT(*) FROM v_seller_integrity_rollup WHERE order_count >= 20
UNION ALL
SELECT 'sellers_high_priority', COUNT(*) FROM v_seller_integrity_rollup WHERE order_count >= 20 AND seller_priority_band = 'High'
UNION ALL
SELECT 'sellers_medium_priority', COUNT(*) FROM v_seller_integrity_rollup WHERE order_count >= 20 AND seller_priority_band = 'Medium';

