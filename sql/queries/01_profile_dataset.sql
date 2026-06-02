-- Basic dataset profile: table counts and event date ranges.

SELECT 'accounts' AS table_name, COUNT(*) AS row_count FROM accounts
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'assets', COUNT(*) FROM assets
UNION ALL SELECT 'activations', COUNT(*) FROM activations
UNION ALL SELECT 'asset_transfers', COUNT(*) FROM asset_transfers
UNION ALL SELECT 'support_tickets', COUNT(*) FROM support_tickets
UNION ALL SELECT 'abuse_reports', COUNT(*) FROM abuse_reports
UNION ALL SELECT 'chargebacks', COUNT(*) FROM chargebacks
UNION ALL SELECT 'watchlist_entities', COUNT(*) FROM watchlist_entities
ORDER BY table_name;

SELECT
    'orders' AS event_table,
    MIN(order_ts) AS first_event_ts,
    MAX(order_ts) AS latest_event_ts
FROM orders
UNION ALL
SELECT 'activations', MIN(activation_ts), MAX(activation_ts) FROM activations
UNION ALL
SELECT 'asset_transfers', MIN(transfer_ts), MAX(transfer_ts) FROM asset_transfers
UNION ALL
SELECT 'abuse_reports', MIN(report_ts), MAX(report_ts) FROM abuse_reports
UNION ALL
SELECT 'chargebacks', MIN(chargeback_ts), MAX(chargeback_ts) FROM chargebacks
ORDER BY event_table;

