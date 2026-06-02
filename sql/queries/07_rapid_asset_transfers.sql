-- Assets transferred shortly after purchase.

SELECT
    tl.asset_id,
    tl.order_id,
    tl.purchaser_account_id,
    tl.order_ts,
    tl.first_transfer_ts,
    DATE_PART('day', tl.first_transfer_ts - tl.order_ts) AS days_to_transfer,
    tl.first_transfer_to_account_id,
    tl.first_transfer_reason,
    tl.shipping_country_code,
    tl.first_transfer_country_code,
    tl.latest_activation_country_code,
    tl.latest_activation_ts
FROM v_asset_lifecycle tl
WHERE tl.first_transfer_ts IS NOT NULL
  AND tl.first_transfer_ts <= tl.order_ts + INTERVAL '14 days'
ORDER BY
    days_to_transfer,
    tl.first_transfer_ts DESC
LIMIT 100;

