-- Fake watchlist hits. This uses synthetic countries, entities, domains, and fingerprints only.

WITH account_hits AS (
    SELECT
        a.account_id,
        w.entity_type,
        w.entity_value,
        w.entity_label,
        w.risk_tier,
        w.reason_code
    FROM accounts a
    JOIN watchlist_entities w
      ON (
            (w.entity_type = 'country_code' AND w.entity_value = a.signup_country_code)
         OR (w.entity_type = 'reseller_id' AND w.entity_value = a.reseller_id)
         OR (w.entity_type = 'email_domain' AND w.entity_value = a.email_domain)
         OR (w.entity_type = 'payment_fingerprint' AND w.entity_value = a.payment_fingerprint)
         OR (w.entity_type = 'device_fingerprint' AND w.entity_value = a.device_fingerprint)
         OR (w.entity_type = 'shipping_address_fingerprint' AND w.entity_value = a.shipping_address_fingerprint)
         OR (w.entity_type = 'phone_fingerprint' AND w.entity_value = a.phone_fingerprint)
         )
    -- Watchlist entries in force on the lab's 2026-06-01 as-of date.
    WHERE w.active_from <= DATE '2026-06-01'
      AND (w.active_to IS NULL OR w.active_to >= DATE '2026-06-01')
),
activation_hits AS (
    SELECT
        a.account_id,
        w.entity_type,
        w.entity_value,
        w.entity_label,
        w.risk_tier,
        w.reason_code
    FROM activations act
    JOIN accounts a
      ON a.account_id = act.account_id
    JOIN watchlist_entities w
      ON w.entity_type = 'country_code'
     AND w.entity_value = act.activation_country_code
    WHERE w.active_from <= DATE '2026-06-01'
      AND (w.active_to IS NULL OR w.active_to >= DATE '2026-06-01')
)
SELECT
    account_id,
    entity_type,
    entity_value,
    entity_label,
    risk_tier,
    reason_code,
    COUNT(*) AS hit_count
FROM (
    SELECT * FROM account_hits
    UNION ALL
    SELECT * FROM activation_hits
) hits
GROUP BY
    account_id,
    entity_type,
    entity_value,
    entity_label,
    risk_tier,
    reason_code
ORDER BY
    risk_tier DESC,
    hit_count DESC,
    account_id;

