DROP VIEW IF EXISTS v_review_queue CASCADE;
DROP VIEW IF EXISTS v_account_risk_flags CASCADE;
DROP VIEW IF EXISTS v_asset_risk_flags CASCADE;
DROP VIEW IF EXISTS v_asset_lifecycle CASCADE;
DROP VIEW IF EXISTS v_order_bursts CASCADE;
DROP VIEW IF EXISTS v_identifier_clusters CASCADE;
DROP VIEW IF EXISTS v_latest_asset_activation CASCADE;

CREATE VIEW v_latest_asset_activation AS
SELECT
    activation_id,
    asset_id,
    account_id,
    activation_ts,
    activation_country_code,
    activation_region,
    ip_fingerprint,
    device_fingerprint
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

CREATE VIEW v_identifier_clusters AS
WITH identifiers AS (
    SELECT account_id, 'payment_fingerprint' AS identifier_type, payment_fingerprint AS identifier_value FROM accounts
    UNION ALL
    SELECT account_id, 'device_fingerprint', device_fingerprint FROM accounts
    UNION ALL
    SELECT account_id, 'phone_fingerprint', phone_fingerprint FROM accounts
    UNION ALL
    SELECT account_id, 'email_fingerprint', email_fingerprint FROM accounts
    UNION ALL
    SELECT account_id, 'email_domain', email_domain FROM accounts
    UNION ALL
    SELECT account_id, 'shipping_address_fingerprint', shipping_address_fingerprint FROM accounts
    UNION ALL
    SELECT account_id, 'support_language', support_language FROM accounts
    UNION ALL
    SELECT account_id, 'reseller_id', reseller_id FROM accounts WHERE reseller_id IS NOT NULL
)
SELECT
    identifier_type,
    identifier_value,
    COUNT(DISTINCT account_id) AS account_count,
    ARRAY_AGG(DISTINCT account_id ORDER BY account_id) AS account_ids
FROM identifiers
WHERE identifier_value IS NOT NULL
  AND identifier_value <> ''
GROUP BY identifier_type, identifier_value
HAVING COUNT(DISTINCT account_id) >= 2;

CREATE VIEW v_order_bursts AS
SELECT
    anchor.account_id,
    anchor.order_ts AS burst_start_ts,
    anchor.order_ts + INTERVAL '24 hours' AS burst_end_ts,
    COUNT(DISTINCT windowed.order_id) AS order_count_24h,
    SUM(windowed.asset_count) AS asset_count_24h,
    SUM(windowed.order_value_usd) AS order_value_24h,
    ARRAY_AGG(DISTINCT windowed.order_id ORDER BY windowed.order_id) AS order_ids
FROM orders anchor
JOIN orders windowed
  ON windowed.account_id = anchor.account_id
 AND windowed.order_ts >= anchor.order_ts
 AND windowed.order_ts < anchor.order_ts + INTERVAL '24 hours'
-- Group by the anchor order's primary key so two orders sharing an exact
-- order_ts cannot merge into one window and double-count the SUMs.
GROUP BY anchor.order_id, anchor.account_id, anchor.order_ts
HAVING COUNT(DISTINCT windowed.order_id) >= 3
    OR SUM(windowed.asset_count) >= 8;

CREATE VIEW v_asset_lifecycle AS
WITH first_transfer AS (
    SELECT
        transfer_id,
        asset_id,
        from_account_id,
        to_account_id,
        transfer_ts,
        transfer_reason,
        initiated_by,
        transfer_country_code
    FROM (
        SELECT
            tt.*,
            ROW_NUMBER() OVER (
                PARTITION BY tt.asset_id
                ORDER BY tt.transfer_ts, tt.transfer_id
            ) AS rn
        FROM asset_transfers tt
    ) ranked
    WHERE rn = 1
)
SELECT
    t.asset_id,
    t.serial_number,
    t.model,
    t.current_status,
    o.order_id,
    o.account_id AS purchaser_account_id,
    o.order_ts,
    o.order_channel,
    o.shipping_country_code,
    ship_country.country_name AS shipping_country_name,
    ship_country.risk_tier AS shipping_risk_tier,
    o.shipping_node_id,
    lta.account_id AS latest_activation_account_id,
    lta.activation_ts AS latest_activation_ts,
    lta.activation_country_code AS latest_activation_country_code,
    activate_country.country_name AS latest_activation_country_name,
    activate_country.risk_tier AS latest_activation_risk_tier,
    activate_country.is_restricted AS latest_activation_is_restricted,
    ft.transfer_ts AS first_transfer_ts,
    ft.to_account_id AS first_transfer_to_account_id,
    ft.transfer_reason AS first_transfer_reason,
    ft.transfer_country_code AS first_transfer_country_code
FROM assets t
JOIN orders o
  ON o.order_id = t.first_order_id
JOIN countries ship_country
  ON ship_country.country_code = o.shipping_country_code
LEFT JOIN v_latest_asset_activation lta
  ON lta.asset_id = t.asset_id
LEFT JOIN countries activate_country
  ON activate_country.country_code = lta.activation_country_code
LEFT JOIN first_transfer ft
  ON ft.asset_id = t.asset_id;

CREATE VIEW v_asset_risk_flags AS
WITH activation_summary AS (
    SELECT
        a.asset_id,
        COUNT(*) AS activation_count,
        COUNT(DISTINCT a.account_id) AS activation_account_count,
        COUNT(DISTINCT a.activation_country_code) AS activation_country_count,
        BOOL_OR(c.is_restricted) AS any_restricted_activation
    FROM activations a
    JOIN countries c
      ON c.country_code = a.activation_country_code
    GROUP BY a.asset_id
),
report_summary AS (
    SELECT
        asset_id,
        COUNT(*) AS asset_abuse_report_count,
        MAX(severity) AS max_asset_abuse_severity,
        MAX(report_ts) AS latest_asset_report_ts
    FROM abuse_reports
    WHERE asset_id IS NOT NULL
    GROUP BY asset_id
),
chargeback_summary AS (
    SELECT
        oi.asset_id,
        COUNT(cb.chargeback_id) AS asset_chargeback_count,
        -- Order-level chargeback total; every asset on the order carries the full amount.
        SUM(cb.amount_usd) AS order_chargeback_amount
    FROM order_items oi
    JOIN chargebacks cb
      ON cb.order_id = oi.order_id
    GROUP BY oi.asset_id
)
SELECT
    tl.asset_id,
    tl.purchaser_account_id,
    tl.order_id,
    tl.order_ts,
    tl.shipping_country_code,
    tl.latest_activation_country_code,
    tl.latest_activation_ts,
    tl.first_transfer_ts,
    tl.first_transfer_to_account_id,
    COALESCE(acts.activation_count, 0) AS activation_count,
    COALESCE(acts.activation_account_count, 0) AS activation_account_count,
    COALESCE(acts.activation_country_count, 0) AS activation_country_count,
    COALESCE(reports.asset_abuse_report_count, 0) AS asset_abuse_report_count,
    COALESCE(reports.max_asset_abuse_severity, 0) AS max_asset_abuse_severity,
    reports.latest_asset_report_ts,
    COALESCE(cb.asset_chargeback_count, 0) AS asset_chargeback_count,
    COALESCE(cb.order_chargeback_amount, 0) AS order_chargeback_amount,
    (tl.latest_activation_country_code IS NOT NULL AND tl.shipping_country_code <> tl.latest_activation_country_code)
        AS shipped_to_activation_mismatch,
    COALESCE(acts.any_restricted_activation, FALSE) AS restricted_activation,
    (tl.first_transfer_ts IS NOT NULL AND tl.first_transfer_ts <= tl.order_ts + INTERVAL '14 days')
        AS transfer_within_14d,
    (COALESCE(acts.activation_account_count, 0) >= 2) AS multiple_activation_accounts,
    (
        tl.latest_activation_risk_tier >= 4
        AND tl.shipping_risk_tier <= 2
        AND tl.latest_activation_country_code IS NOT NULL
        AND tl.shipping_country_code <> tl.latest_activation_country_code
    ) AS movement_to_higher_risk_geo
FROM v_asset_lifecycle tl
LEFT JOIN activation_summary acts
  ON acts.asset_id = tl.asset_id
LEFT JOIN report_summary reports
  ON reports.asset_id = tl.asset_id
LEFT JOIN chargeback_summary cb
  ON cb.asset_id = tl.asset_id;

CREATE VIEW v_account_risk_flags AS
WITH cluster_members AS (
    SELECT
        member.account_id,
        c.identifier_type,
        c.account_count
    FROM v_identifier_clusters c
    CROSS JOIN LATERAL UNNEST(c.account_ids) AS member(account_id)
),
cluster_rollup AS (
    SELECT
        account_id,
        MAX(CASE WHEN identifier_type = 'payment_fingerprint' THEN account_count ELSE 0 END) AS shared_payment_accounts,
        MAX(CASE WHEN identifier_type = 'device_fingerprint' THEN account_count ELSE 0 END) AS shared_device_accounts,
        MAX(CASE WHEN identifier_type = 'phone_fingerprint' THEN account_count ELSE 0 END) AS shared_phone_accounts,
        MAX(CASE WHEN identifier_type = 'email_fingerprint' THEN account_count ELSE 0 END) AS shared_email_accounts,
        MAX(CASE WHEN identifier_type = 'shipping_address_fingerprint' THEN account_count ELSE 0 END) AS shared_shipping_accounts,
        MAX(CASE WHEN identifier_type = 'reseller_id' THEN account_count ELSE 0 END) AS shared_reseller_accounts
    FROM cluster_members
    GROUP BY account_id
),
order_rollup AS (
    SELECT
        account_id,
        COUNT(*) AS order_count,
        SUM(asset_count) AS asset_count,
        SUM(order_value_usd) AS order_value_usd,
        MIN(order_ts) AS first_order_ts,
        MAX(order_ts) AS latest_order_ts
    FROM orders
    GROUP BY account_id
),
burst_rollup AS (
    SELECT
        account_id,
        MAX(order_count_24h) AS max_orders_24h,
        MAX(asset_count_24h) AS max_assets_24h
    FROM v_order_bursts
    GROUP BY account_id
),
chargeback_rollup AS (
    SELECT
        account_id,
        COUNT(*) AS chargeback_count,
        SUM(amount_usd) AS chargeback_amount_usd,
        MAX(chargeback_ts) AS latest_chargeback_ts
    FROM chargebacks
    GROUP BY account_id
),
abuse_rollup AS (
    SELECT
        account_id,
        COUNT(*) AS account_abuse_report_count,
        MAX(severity) AS max_account_abuse_severity,
        MAX(report_ts) AS latest_account_report_ts
    FROM abuse_reports
    WHERE account_id IS NOT NULL
    GROUP BY account_id
),
asset_flag_rollup AS (
    SELECT
        purchaser_account_id AS account_id,
        COUNT(*) FILTER (WHERE shipped_to_activation_mismatch) AS mismatch_asset_count,
        COUNT(*) FILTER (WHERE restricted_activation) AS restricted_activation_asset_count,
        COUNT(*) FILTER (WHERE transfer_within_14d) AS rapid_transfer_asset_count,
        COUNT(*) FILTER (WHERE movement_to_higher_risk_geo) AS high_risk_movement_asset_count
    FROM v_asset_risk_flags
    GROUP BY purchaser_account_id
),
watchlist_rollup AS (
    SELECT
        a.account_id,
        BOOL_OR(w.entity_type = 'country_code') AS watchlisted_signup_country,
        BOOL_OR(w.entity_type = 'reseller_id') AS watchlisted_reseller,
        BOOL_OR(w.entity_type = 'email_domain') AS watchlisted_email_domain,
        BOOL_OR(w.entity_type = 'payment_fingerprint') AS watchlisted_payment,
        BOOL_OR(w.entity_type = 'device_fingerprint') AS watchlisted_device,
        BOOL_OR(w.entity_type = 'shipping_address_fingerprint') AS watchlisted_shipping_address,
        BOOL_OR(w.entity_type = 'phone_fingerprint') AS watchlisted_phone
    FROM accounts a
    LEFT JOIN watchlist_entities w
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
     AND w.active_from <= DATE '2026-06-01'
     AND (w.active_to IS NULL OR w.active_to >= DATE '2026-06-01')
    GROUP BY a.account_id
)
SELECT
    a.account_id,
    a.created_at,
    DATE_PART('day', TIMESTAMP '2026-06-01 00:00:00' - a.created_at) AS account_age_days,
    a.account_type,
    a.signup_country_code,
    c.risk_tier AS signup_country_risk_tier,
    c.is_restricted AS signup_country_is_restricted,
    a.email_domain,
    a.reseller_id,
    a.status,
    COALESCE(oroll.order_count, 0) AS order_count,
    COALESCE(oroll.asset_count, 0) AS asset_count,
    COALESCE(oroll.order_value_usd, 0) AS order_value_usd,
    oroll.first_order_ts,
    oroll.latest_order_ts,
    COALESCE(broll.max_orders_24h, 0) AS max_orders_24h,
    COALESCE(broll.max_assets_24h, 0) AS max_assets_24h,
    COALESCE(cb.chargeback_count, 0) AS chargeback_count,
    COALESCE(cb.chargeback_amount_usd, 0) AS chargeback_amount_usd,
    cb.latest_chargeback_ts,
    COALESCE(ab.account_abuse_report_count, 0) AS account_abuse_report_count,
    COALESCE(ab.max_account_abuse_severity, 0) AS max_account_abuse_severity,
    ab.latest_account_report_ts,
    COALESCE(cr.shared_payment_accounts, 0) AS shared_payment_accounts,
    COALESCE(cr.shared_device_accounts, 0) AS shared_device_accounts,
    COALESCE(cr.shared_phone_accounts, 0) AS shared_phone_accounts,
    COALESCE(cr.shared_email_accounts, 0) AS shared_email_accounts,
    COALESCE(cr.shared_shipping_accounts, 0) AS shared_shipping_accounts,
    COALESCE(cr.shared_reseller_accounts, 0) AS shared_reseller_accounts,
    COALESCE(tfr.mismatch_asset_count, 0) AS mismatch_asset_count,
    COALESCE(tfr.restricted_activation_asset_count, 0) AS restricted_activation_asset_count,
    COALESCE(tfr.rapid_transfer_asset_count, 0) AS rapid_transfer_asset_count,
    COALESCE(tfr.high_risk_movement_asset_count, 0) AS high_risk_movement_asset_count,
    COALESCE(wr.watchlisted_signup_country, FALSE) AS watchlisted_signup_country,
    COALESCE(wr.watchlisted_reseller, FALSE) AS watchlisted_reseller,
    COALESCE(wr.watchlisted_email_domain, FALSE) AS watchlisted_email_domain,
    COALESCE(wr.watchlisted_payment, FALSE) AS watchlisted_payment,
    COALESCE(wr.watchlisted_device, FALSE) AS watchlisted_device,
    COALESCE(wr.watchlisted_shipping_address, FALSE) AS watchlisted_shipping_address,
    COALESCE(wr.watchlisted_phone, FALSE) AS watchlisted_phone
FROM accounts a
JOIN countries c
  ON c.country_code = a.signup_country_code
LEFT JOIN order_rollup oroll
  ON oroll.account_id = a.account_id
LEFT JOIN burst_rollup broll
  ON broll.account_id = a.account_id
LEFT JOIN chargeback_rollup cb
  ON cb.account_id = a.account_id
LEFT JOIN abuse_rollup ab
  ON ab.account_id = a.account_id
LEFT JOIN cluster_rollup cr
  ON cr.account_id = a.account_id
LEFT JOIN asset_flag_rollup tfr
  ON tfr.account_id = a.account_id
LEFT JOIN watchlist_rollup wr
  ON wr.account_id = a.account_id;

CREATE VIEW v_review_queue AS
WITH account_scored AS (
    SELECT
        'account'::TEXT AS entity_type,
        account_id AS entity_id,
        GREATEST(latest_order_ts, latest_chargeback_ts, latest_account_report_ts) AS last_event_at,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN shared_payment_accounts >= 3 THEN 'shared_payment_3plus' END,
            CASE WHEN shared_device_accounts >= 3 THEN 'shared_device_3plus' END,
            CASE WHEN shared_phone_accounts >= 3 THEN 'shared_phone_3plus' END,
            CASE WHEN shared_shipping_accounts >= 3 THEN 'shared_shipping_3plus' END,
            CASE WHEN max_orders_24h >= 3 OR max_assets_24h >= 8 THEN 'bulk_order_24h' END,
            CASE WHEN chargeback_count >= 2 THEN 'multiple_chargebacks' END,
            CASE WHEN order_count > 0 AND chargeback_count::NUMERIC / order_count >= 0.30 THEN 'high_chargeback_rate' END,
            CASE WHEN account_abuse_report_count >= 3 THEN 'repeated_abuse_reports' END,
            CASE WHEN restricted_activation_asset_count > 0 THEN 'owned_asset_restricted_activation' END,
            CASE WHEN rapid_transfer_asset_count > 0 THEN 'owned_asset_rapid_transfer' END,
            CASE WHEN high_risk_movement_asset_count > 0 THEN 'owned_asset_high_risk_movement' END,
            CASE WHEN watchlisted_signup_country THEN 'fake_watchlist_signup_country' END,
            CASE WHEN watchlisted_reseller THEN 'fake_watchlist_reseller' END,
            CASE WHEN watchlisted_email_domain THEN 'fake_watchlist_email_domain' END,
            CASE WHEN watchlisted_payment THEN 'fake_watchlist_payment' END,
            CASE WHEN watchlisted_device THEN 'fake_watchlist_device' END
        ], NULL) AS risk_flags,
        (
            CASE WHEN shared_payment_accounts >= 3 THEN 25 ELSE 0 END +
            CASE WHEN shared_device_accounts >= 3 THEN 20 ELSE 0 END +
            CASE WHEN shared_phone_accounts >= 3 THEN 15 ELSE 0 END +
            CASE WHEN shared_shipping_accounts >= 3 THEN 15 ELSE 0 END +
            CASE WHEN max_orders_24h >= 3 OR max_assets_24h >= 8 THEN 25 ELSE 0 END +
            CASE WHEN chargeback_count >= 2 THEN 30 ELSE 0 END +
            CASE WHEN order_count > 0 AND chargeback_count::NUMERIC / order_count >= 0.30 THEN 15 ELSE 0 END +
            CASE WHEN account_abuse_report_count >= 3 THEN 25 ELSE 0 END +
            CASE WHEN restricted_activation_asset_count > 0 THEN 30 ELSE 0 END +
            CASE WHEN rapid_transfer_asset_count > 0 THEN 20 ELSE 0 END +
            CASE WHEN high_risk_movement_asset_count > 0 THEN 25 ELSE 0 END +
            CASE WHEN watchlisted_signup_country THEN 35 ELSE 0 END +
            CASE WHEN watchlisted_reseller THEN 30 ELSE 0 END +
            CASE WHEN watchlisted_email_domain THEN 20 ELSE 0 END +
            CASE WHEN watchlisted_payment THEN 35 ELSE 0 END +
            CASE WHEN watchlisted_device THEN 30 ELSE 0 END
        ) AS priority_score,
        JSONB_BUILD_OBJECT(
            'account_age_days', account_age_days,
            'signup_country_code', signup_country_code,
            'account_type', account_type,
            'order_count', order_count,
            'asset_count', asset_count,
            'chargeback_count', chargeback_count,
            'abuse_report_count', account_abuse_report_count,
            'max_orders_24h', max_orders_24h,
            'max_assets_24h', max_assets_24h,
            'shared_payment_accounts', shared_payment_accounts,
            'shared_device_accounts', shared_device_accounts,
            'shared_shipping_accounts', shared_shipping_accounts,
            'reseller_id', reseller_id
        ) AS supporting_facts
    FROM v_account_risk_flags
),
asset_scored AS (
    SELECT
        'asset'::TEXT AS entity_type,
        asset_id AS entity_id,
        GREATEST(latest_activation_ts, first_transfer_ts, latest_asset_report_ts, order_ts) AS last_event_at,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN shipped_to_activation_mismatch THEN 'ship_activate_country_mismatch' END,
            CASE WHEN restricted_activation THEN 'fake_restricted_country_activation' END,
            CASE WHEN transfer_within_14d THEN 'transfer_within_14d' END,
            CASE WHEN multiple_activation_accounts THEN 'multiple_activation_accounts' END,
            CASE WHEN asset_abuse_report_count >= 2 THEN 'repeated_asset_abuse_reports' END,
            CASE WHEN asset_chargeback_count > 0 THEN 'chargeback_linked_order' END,
            CASE WHEN movement_to_higher_risk_geo THEN 'movement_to_higher_risk_geo' END
        ], NULL) AS risk_flags,
        (
            CASE WHEN shipped_to_activation_mismatch THEN 25 ELSE 0 END +
            CASE WHEN restricted_activation THEN 40 ELSE 0 END +
            CASE WHEN transfer_within_14d THEN 30 ELSE 0 END +
            CASE WHEN multiple_activation_accounts THEN 20 ELSE 0 END +
            CASE WHEN asset_abuse_report_count >= 2 THEN 25 ELSE 0 END +
            CASE WHEN asset_chargeback_count > 0 THEN 25 ELSE 0 END +
            CASE WHEN movement_to_higher_risk_geo THEN 25 ELSE 0 END
        ) AS priority_score,
        JSONB_BUILD_OBJECT(
            'purchaser_account_id', purchaser_account_id,
            'order_id', order_id,
            'order_ts', order_ts,
            'shipping_country_code', shipping_country_code,
            'latest_activation_country_code', latest_activation_country_code,
            'activation_count', activation_count,
            'activation_account_count', activation_account_count,
            'asset_abuse_report_count', asset_abuse_report_count,
            'asset_chargeback_count', asset_chargeback_count,
            'first_transfer_ts', first_transfer_ts,
            'first_transfer_to_account_id', first_transfer_to_account_id
        ) AS supporting_facts
    FROM v_asset_risk_flags
),
combined AS (
    SELECT * FROM account_scored
    UNION ALL
    SELECT * FROM asset_scored
)
SELECT
    NOW() AS generated_at,
    entity_type,
    entity_id,
    last_event_at,
    priority_score,
    CASE
        WHEN priority_score >= 90 THEN 'Critical'
        WHEN priority_score >= 60 THEN 'High'
        WHEN priority_score >= 35 THEN 'Medium'
        ELSE 'Low'
    END AS priority_band,
    risk_flags,
    supporting_facts
FROM combined
WHERE priority_score > 0;
