-- Repeated abuse reports by account, asset, country, and day.

SELECT
    account_id,
    COUNT(*) AS report_count,
    MAX(severity) AS max_severity,
    MIN(report_ts) AS first_report_ts,
    MAX(report_ts) AS latest_report_ts,
    ARRAY_AGG(DISTINCT report_type ORDER BY report_type) AS report_types,
    ARRAY_AGG(DISTINCT country_code ORDER BY country_code) AS countries
FROM abuse_reports
WHERE account_id IS NOT NULL
GROUP BY account_id
HAVING COUNT(*) >= 2
ORDER BY
    report_count DESC,
    max_severity DESC,
    latest_report_ts DESC;

SELECT
    asset_id,
    COUNT(*) AS report_count,
    MAX(severity) AS max_severity,
    MIN(report_ts) AS first_report_ts,
    MAX(report_ts) AS latest_report_ts,
    ARRAY_AGG(DISTINCT report_type ORDER BY report_type) AS report_types,
    ARRAY_AGG(DISTINCT country_code ORDER BY country_code) AS countries
FROM abuse_reports
WHERE asset_id IS NOT NULL
GROUP BY asset_id
HAVING COUNT(*) >= 2
ORDER BY
    report_count DESC,
    max_severity DESC,
    latest_report_ts DESC;

SELECT
    DATE_TRUNC('day', report_ts) AS report_day,
    country_code,
    report_type,
    COUNT(*) AS report_count,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    COUNT(DISTINCT asset_id) AS distinct_assets,
    MAX(severity) AS max_severity
FROM abuse_reports
GROUP BY
    DATE_TRUNC('day', report_ts),
    country_code,
    report_type
HAVING COUNT(*) >= 2
ORDER BY
    report_count DESC,
    report_day DESC;

