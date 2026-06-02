-- Timeline for the highest-scoring queued asset.
-- Replace the target CTE with a specific asset_id for case-focused review.

WITH target AS (
    SELECT entity_id AS asset_id
    FROM review_queue
    WHERE entity_type = 'asset'
    ORDER BY priority_score DESC, last_event_at DESC NULLS LAST
    LIMIT 1
),
order_events AS (
    SELECT
        oi.asset_id,
        o.order_ts AS event_ts,
        'order' AS event_type,
        o.account_id AS actor_account_id,
        o.shipping_country_code AS country_code,
        o.order_id AS detail_id,
        o.order_channel AS detail
    FROM order_items oi
    JOIN orders o
      ON o.order_id = oi.order_id
    JOIN target t
      ON t.asset_id = oi.asset_id
),
activation_events AS (
    SELECT
        a.asset_id,
        a.activation_ts AS event_ts,
        'activation' AS event_type,
        a.account_id AS actor_account_id,
        a.activation_country_code AS country_code,
        a.activation_id AS detail_id,
        a.activation_region AS detail
    FROM activations a
    JOIN target t
      ON t.asset_id = a.asset_id
),
transfer_events AS (
    SELECT
        tt.asset_id,
        tt.transfer_ts AS event_ts,
        'transfer' AS event_type,
        tt.to_account_id AS actor_account_id,
        tt.transfer_country_code AS country_code,
        tt.transfer_id AS detail_id,
        tt.transfer_reason AS detail
    FROM asset_transfers tt
    JOIN target t
      ON t.asset_id = tt.asset_id
),
abuse_events AS (
    SELECT
        ar.asset_id,
        ar.report_ts AS event_ts,
        'abuse_report' AS event_type,
        ar.account_id AS actor_account_id,
        ar.country_code,
        ar.report_id AS detail_id,
        ar.report_type AS detail
    FROM abuse_reports ar
    JOIN target t
      ON t.asset_id = ar.asset_id
)
SELECT *
FROM (
    SELECT * FROM order_events
    UNION ALL
    SELECT * FROM activation_events
    UNION ALL
    SELECT * FROM transfer_events
    UNION ALL
    SELECT * FROM abuse_events
) timeline
ORDER BY event_ts, event_type;

