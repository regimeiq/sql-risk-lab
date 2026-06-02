DROP TABLE IF EXISTS review_queue;

CREATE TABLE review_queue AS
SELECT
    generated_at,
    entity_type,
    entity_id,
    last_event_at,
    priority_score,
    priority_band,
    risk_flags,
    supporting_facts
FROM v_review_queue
WHERE priority_score >= 35
ORDER BY
    priority_score DESC,
    last_event_at DESC NULLS LAST,
    entity_type,
    entity_id;

CREATE INDEX idx_review_queue_priority ON review_queue(priority_band, priority_score DESC);
CREATE INDEX idx_review_queue_entity ON review_queue(entity_type, entity_id);
CREATE INDEX idx_review_queue_flags ON review_queue USING GIN(risk_flags);

COMMENT ON TABLE review_queue IS
'Deterministic synthetic review queue. Scores are triage aids, not conclusions or enforcement decisions.';

