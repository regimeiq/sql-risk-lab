-- Bulk order bursts within rolling 24-hour windows.

SELECT
    ob.account_id,
    a.account_type,
    a.signup_country_code,
    a.reseller_id,
    ob.burst_start_ts,
    ob.burst_end_ts,
    ob.order_count_24h,
    ob.asset_count_24h,
    ob.order_value_24h,
    ob.order_ids
FROM v_order_bursts ob
JOIN accounts a
  ON a.account_id = ob.account_id
ORDER BY
    ob.asset_count_24h DESC,
    ob.order_count_24h DESC,
    ob.burst_start_ts
LIMIT 100;

