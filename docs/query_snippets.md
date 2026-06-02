# Representative Query Snippets

These snippets are shortened examples. Full queries live under `sql/queries/` and `case_studies/olist_marketplace_integrity/sql/queries/`.

## Latest Activation Per Asset

```sql
SELECT
    activation_id,
    asset_id,
    account_id,
    activation_ts,
    activation_country_code
FROM (
    SELECT
        a.*,
        ROW_NUMBER() OVER (
            PARTITION BY a.asset_id
            ORDER BY a.activation_ts DESC, a.activation_id DESC
        ) AS rn
    FROM activations a
) ranked
WHERE rn = 1;
```

## Shared Identifier Clusters

```sql
WITH identifiers AS (
    SELECT account_id, 'payment_fingerprint' AS identifier_type, payment_fingerprint AS identifier_value FROM accounts
    UNION ALL
    SELECT account_id, 'device_fingerprint', device_fingerprint FROM accounts
    UNION ALL
    SELECT account_id, 'shipping_address_fingerprint', shipping_address_fingerprint FROM accounts
)
SELECT
    identifier_type,
    identifier_value,
    COUNT(DISTINCT account_id) AS account_count,
    ARRAY_AGG(DISTINCT account_id ORDER BY account_id) AS account_ids
FROM identifiers
GROUP BY identifier_type, identifier_value
HAVING COUNT(DISTINCT account_id) >= 2;
```

## Rolling Bulk Order Window

```sql
SELECT
    anchor.account_id,
    anchor.order_ts AS burst_start_ts,
    COUNT(DISTINCT windowed.order_id) AS order_count_24h,
    SUM(windowed.asset_count) AS asset_count_24h
FROM orders anchor
JOIN orders windowed
  ON windowed.account_id = anchor.account_id
 AND windowed.order_ts >= anchor.order_ts
 AND windowed.order_ts < anchor.order_ts + INTERVAL '24 hours'
GROUP BY anchor.account_id, anchor.order_ts
HAVING COUNT(DISTINCT windowed.order_id) >= 3
    OR SUM(windowed.asset_count) >= 8;
```

## Olist Order Queue Scoring

```sql
SELECT
    order_id,
    customer_state,
    seller_states,
    categories,
    priority_score,
    priority_band,
    risk_flags
FROM v_order_integrity_queue
ORDER BY priority_score DESC, order_purchase_timestamp DESC
LIMIT 100;
```

## Olist Seller Rollup

```sql
SELECT
    seller_id,
    seller_state,
    order_count,
    late_delivery_rate,
    low_review_rate,
    seller_priority_score,
    seller_priority_band
FROM v_seller_integrity_rollup
WHERE order_count >= 20
ORDER BY seller_priority_score DESC, order_count DESC;
```

