# Limitations

SQL Risk Lab is a public-safe analyst workflow project. It is designed to demonstrate schema design, SQL investigation patterns, deterministic scoring, and review queue construction. It is not a production fraud, compliance, or enforcement system.

## Synthetic Lab

- All synthetic countries, entities, accounts, addresses, devices, assets, payments, resellers, and watchlist values are invented.
- Identifier fields are represented as fingerprints rather than raw PII.
- Country risk tiers are fake and do not map to real jurisdictions.
- Watchlist entries are fake and exist only to demonstrate matching logic.
- Injected scenarios are controlled examples, not evidence that the scoring approach would catch real-world misconduct.
- Risk weights are illustrative and should be calibrated against real labels and operational outcomes in a production environment.
- False positives are expected, especially for shared identifiers, reseller behavior, travel, and legitimate asset transfers.
- False negatives are expected where risky behavior avoids reuse, delays movement, or stays below threshold-based rules.

## Olist Case Study

- Olist is public marketplace data and does not include confirmed fraud, abuse, sanctions, diversion, or enforcement labels.
- Olist outputs are framed as marketplace integrity and operational triage signals: fulfillment risk, low-review patterns, seller quality, payment/installment review, and customer-impact analysis.
- Olist review queue scores should not be read as fraud findings.
- Raw Olist CSVs and the local SQLite database are ignored and should not be committed.

## Public-Safe Boundaries

- The project avoids real restricted-party lists, real sanctions programs, real export-control classifications, real customer records, and real evasion instructions.
- Diversion-style examples use fake geographies and fake entities only.
- The project is not legal, compliance, or enforcement advice.

