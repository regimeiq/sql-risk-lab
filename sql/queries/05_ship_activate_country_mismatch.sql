-- Assets shipped to one synthetic country and activated in another.

SELECT
    trf.asset_id,
    trf.purchaser_account_id,
    trf.order_id,
    trf.order_ts,
    trf.shipping_country_code,
    ship.country_name AS shipping_country,
    trf.latest_activation_ts,
    trf.latest_activation_country_code,
    activated.country_name AS activation_country,
    activated.risk_tier AS activation_risk_tier,
    activated.is_restricted AS activation_is_restricted,
    trf.transfer_within_14d,
    trf.movement_to_higher_risk_geo
FROM v_asset_risk_flags trf
JOIN countries ship
  ON ship.country_code = trf.shipping_country_code
LEFT JOIN countries activated
  ON activated.country_code = trf.latest_activation_country_code
WHERE trf.shipped_to_activation_mismatch
ORDER BY
    activated.is_restricted DESC NULLS LAST,
    activated.risk_tier DESC NULLS LAST,
    trf.latest_activation_ts DESC
LIMIT 100;

