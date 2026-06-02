-- Materialized review queue. Run sql/30_review_queue.sql first.

SELECT
    entity_type,
    entity_id,
    priority_band,
    priority_score,
    last_event_at,
    risk_flags,
    supporting_facts
FROM review_queue
ORDER BY
    priority_score DESC,
    last_event_at DESC NULLS LAST,
    entity_type,
    entity_id
LIMIT 100;

