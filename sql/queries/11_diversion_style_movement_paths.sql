-- Diversion-style paths: low-risk purchase/shipping followed by higher-risk transfer or activation.

SELECT
    tl.asset_id,
    tl.order_id,
    tl.purchaser_account_id,
    tl.order_ts,
    tl.shipping_country_code,
    tl.shipping_country_name,
    tl.shipping_risk_tier,
    tl.first_transfer_ts,
    tl.first_transfer_to_account_id,
    tl.first_transfer_country_code,
    transfer_country.risk_tier AS transfer_country_risk_tier,
    tl.latest_activation_ts,
    tl.latest_activation_account_id,
    tl.latest_activation_country_code,
    tl.latest_activation_country_name,
    tl.latest_activation_risk_tier,
    tl.latest_activation_is_restricted
FROM v_asset_lifecycle tl
LEFT JOIN countries transfer_country
  ON transfer_country.country_code = tl.first_transfer_country_code
WHERE tl.shipping_risk_tier <= 2
  AND (
        tl.latest_activation_risk_tier >= 4
     OR tl.latest_activation_is_restricted
     OR transfer_country.risk_tier >= 4
      )
ORDER BY
    tl.latest_activation_is_restricted DESC NULLS LAST,
    GREATEST(tl.first_transfer_ts, tl.latest_activation_ts) DESC NULLS LAST
LIMIT 100;

