-- Shared identifiers across accounts. Support language is excluded here because it is often common by design.

SELECT
    identifier_type,
    identifier_value,
    account_count,
    account_ids
FROM v_identifier_clusters
WHERE identifier_type <> 'support_language'
ORDER BY
    account_count DESC,
    identifier_type,
    identifier_value
LIMIT 100;

