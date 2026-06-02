-- Explain which flags drive the review queue.

WITH exploded_flags AS (
    SELECT
        rq.entity_type,
        rq.entity_id,
        rq.priority_band,
        rq.priority_score,
        flag.risk_flag
    FROM review_queue rq
    CROSS JOIN LATERAL UNNEST(rq.risk_flags) AS flag(risk_flag)
)
SELECT
    risk_flag,
    COUNT(*) AS queued_entities,
    COUNT(*) FILTER (WHERE entity_type = 'account') AS account_entities,
    COUNT(*) FILTER (WHERE entity_type = 'asset') AS asset_entities,
    ROUND(AVG(priority_score), 1) AS avg_priority_score,
    MAX(priority_score) AS max_priority_score
FROM exploded_flags
GROUP BY risk_flag
ORDER BY
    queued_entities DESC,
    max_priority_score DESC,
    risk_flag;

SELECT
    priority_band,
    entity_type,
    COUNT(*) AS queued_entities,
    ROUND(AVG(priority_score), 1) AS avg_priority_score,
    MIN(priority_score) AS min_priority_score,
    MAX(priority_score) AS max_priority_score
FROM review_queue
GROUP BY
    priority_band,
    entity_type
ORDER BY
    CASE priority_band
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        ELSE 4
    END,
    entity_type;

