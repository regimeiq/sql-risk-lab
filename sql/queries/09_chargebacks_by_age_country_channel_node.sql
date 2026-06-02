-- Chargebacks grouped by account age, signup country, order channel, and shipping node.

WITH order_base AS (
    SELECT
        o.order_id,
        o.account_id,
        o.order_ts,
        o.order_channel,
        o.shipping_country_code,
        o.shipping_node_id,
        o.order_value_usd,
        a.created_at AS account_created_at,
        CASE
            WHEN o.order_ts < a.created_at + INTERVAL '7 days' THEN '00-06 days'
            WHEN o.order_ts < a.created_at + INTERVAL '30 days' THEN '07-29 days'
            WHEN o.order_ts < a.created_at + INTERVAL '90 days' THEN '30-89 days'
            ELSE '90+ days'
        END AS account_age_bucket
    FROM orders o
    JOIN accounts a
      ON a.account_id = o.account_id
)
SELECT
    ob.account_age_bucket,
    ob.shipping_country_code,
    c.risk_tier AS shipping_country_risk_tier,
    ob.order_channel,
    ob.shipping_node_id,
    COUNT(DISTINCT ob.order_id) AS order_count,
    COUNT(DISTINCT cb.chargeback_id) AS chargeback_count,
    ROUND(
        COUNT(DISTINCT cb.chargeback_id)::NUMERIC / NULLIF(COUNT(DISTINCT ob.order_id), 0),
        3
    ) AS chargeback_rate,
    SUM(ob.order_value_usd) AS gross_order_value_usd,
    COALESCE(SUM(cb.amount_usd), 0) AS chargeback_amount_usd
FROM order_base ob
JOIN countries c
  ON c.country_code = ob.shipping_country_code
LEFT JOIN chargebacks cb
  ON cb.order_id = ob.order_id
GROUP BY
    ob.account_age_bucket,
    ob.shipping_country_code,
    c.risk_tier,
    ob.order_channel,
    ob.shipping_node_id
HAVING COUNT(DISTINCT cb.chargeback_id) > 0
ORDER BY
    chargeback_rate DESC,
    chargeback_count DESC,
    gross_order_value_usd DESC;

