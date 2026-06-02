-- Account network view for stronger shared identifiers.
-- This is useful for finding rings connected by payment, device, phone, or shipping address.

WITH selected_clusters AS (
    SELECT
        identifier_type,
        identifier_value,
        account_count,
        account_ids
    FROM v_identifier_clusters
    WHERE identifier_type IN (
        'payment_fingerprint',
        'device_fingerprint',
        'phone_fingerprint',
        'shipping_address_fingerprint',
        'reseller_id'
    )
      AND account_count >= 3
),
members AS (
    SELECT
        sc.identifier_type,
        sc.identifier_value,
        sc.account_count,
        member.account_id
    FROM selected_clusters sc
    CROSS JOIN LATERAL UNNEST(sc.account_ids) AS member(account_id)
)
SELECT
    m.account_id,
    a.created_at,
    a.account_type,
    a.signup_country_code,
    a.status,
    a.reseller_id,
    STRING_AGG(DISTINCT m.identifier_type, ', ' ORDER BY m.identifier_type) AS shared_identifier_types,
    MAX(m.account_count) AS largest_cluster_size,
    COUNT(DISTINCT o.order_id) AS order_count,
    COALESCE(SUM(o.asset_count), 0) AS asset_count,
    COUNT(DISTINCT cb.chargeback_id) AS chargeback_count
FROM members m
JOIN accounts a
  ON a.account_id = m.account_id
LEFT JOIN orders o
  ON o.account_id = a.account_id
LEFT JOIN chargebacks cb
  ON cb.account_id = a.account_id
GROUP BY
    m.account_id,
    a.created_at,
    a.account_type,
    a.signup_country_code,
    a.status,
    a.reseller_id
ORDER BY
    largest_cluster_size DESC,
    chargeback_count DESC,
    asset_count DESC,
    m.account_id;

