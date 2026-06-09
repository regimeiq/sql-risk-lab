-- Account network view for stronger shared identifiers.
-- This is useful for finding rings connected by payment, device, phone, or shipping address.
-- Orders and chargebacks are pre-aggregated per account before joining, so the
-- one-to-many joins cannot fan out and inflate SUM(asset_count).

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
),
member_rollup AS (
    SELECT
        account_id,
        STRING_AGG(DISTINCT identifier_type, ', ' ORDER BY identifier_type) AS shared_identifier_types,
        MAX(account_count) AS largest_cluster_size
    FROM members
    GROUP BY account_id
),
order_rollup AS (
    SELECT
        account_id,
        COUNT(*) AS order_count,
        SUM(asset_count) AS asset_count
    FROM orders
    GROUP BY account_id
),
chargeback_rollup AS (
    SELECT
        account_id,
        COUNT(*) AS chargeback_count
    FROM chargebacks
    GROUP BY account_id
)
SELECT
    mr.account_id,
    a.created_at,
    a.account_type,
    a.signup_country_code,
    a.status,
    a.reseller_id,
    mr.shared_identifier_types,
    mr.largest_cluster_size,
    COALESCE(oroll.order_count, 0) AS order_count,
    COALESCE(oroll.asset_count, 0) AS asset_count,
    COALESCE(cb.chargeback_count, 0) AS chargeback_count
FROM member_rollup mr
JOIN accounts a
  ON a.account_id = mr.account_id
LEFT JOIN order_rollup oroll
  ON oroll.account_id = mr.account_id
LEFT JOIN chargeback_rollup cb
  ON cb.account_id = mr.account_id
ORDER BY
    largest_cluster_size DESC,
    chargeback_count DESC,
    asset_count DESC,
    mr.account_id;
