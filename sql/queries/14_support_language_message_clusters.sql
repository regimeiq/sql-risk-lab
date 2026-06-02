-- Support language and repeated message fingerprint patterns.

SELECT
    support_language,
    message_fingerprint,
    COUNT(*) AS ticket_count,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    COUNT(DISTINCT asset_id) FILTER (WHERE asset_id IS NOT NULL) AS distinct_assets,
    ARRAY_AGG(DISTINCT reason_code ORDER BY reason_code) AS reason_codes,
    MIN(opened_at) AS first_seen,
    MAX(opened_at) AS latest_seen
FROM support_tickets
GROUP BY
    support_language,
    message_fingerprint
HAVING COUNT(DISTINCT account_id) >= 3
ORDER BY
    distinct_accounts DESC,
    ticket_count DESC,
    latest_seen DESC;

SELECT
    st.support_language,
    st.reason_code,
    a.signup_country_code,
    COUNT(*) AS ticket_count,
    COUNT(DISTINCT st.account_id) AS distinct_accounts,
    COUNT(DISTINCT st.message_fingerprint) AS distinct_messages
FROM support_tickets st
JOIN accounts a
  ON a.account_id = st.account_id
GROUP BY
    st.support_language,
    st.reason_code,
    a.signup_country_code
HAVING COUNT(*) >= 5
ORDER BY
    ticket_count DESC,
    distinct_accounts DESC;

