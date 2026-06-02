-- Latest activation and latest observed activation country per asset.

SELECT
    tl.asset_id,
    tl.serial_number,
    tl.model,
    tl.purchaser_account_id,
    tl.order_ts,
    tl.shipping_country_code,
    tl.latest_activation_ts,
    tl.latest_activation_account_id,
    tl.latest_activation_country_code,
    tl.latest_activation_country_name,
    tl.latest_activation_risk_tier,
    tl.latest_activation_is_restricted
FROM v_asset_lifecycle tl
WHERE tl.latest_activation_ts IS NOT NULL
ORDER BY tl.latest_activation_ts DESC
LIMIT 100;

