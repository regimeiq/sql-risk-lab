# Methodology

SQL Risk Lab uses controlled synthetic data and a public real-world marketplace dataset to demonstrate analyst-style SQL workflows. The goal is not to predict real-world misconduct. The goal is to show how structured data can be joined, grouped, windowed, and scored to support review prioritization.

## Synthetic Design

The data generator creates normal-looking background activity and injects specific risk scenarios:

- Shared identifier clusters across accounts.
- Bulk order bursts inside short time windows.
- Asset transfers shortly after purchase.
- Ship-to and activate-in country mismatches.
- Activation in fake restricted or high-risk countries.
- Repeated abuse reports tied to the same accounts, assets, or time windows.
- Chargebacks after suspicious order patterns.
- Watchlist hits against fake reseller, country, email-domain, and identifier entries.

The dataset is deterministic when a seed is supplied. This keeps query output reproducible for portfolio review and future regression checks.

## Analyst Workflow

The synthetic lab workflow follows five steps:

1. Profile the dataset for table counts, date ranges, and coverage gaps.
2. Build latest-state views for assets and accounts.
3. Identify clusters and anomalies using SQL joins, grouping, and window functions.
4. Convert investigation signals into explainable risk flags.
5. Produce a review queue ordered by transparent priority score.

## Olist Companion Workflow

The Olist case study applies a similar workflow to public marketplace data:

1. Load public Olist CSVs into a local SQLite database.
2. Build order-level features for delivery timing, payment patterns, item counts, category, seller geography, and review scores.
3. Build seller-level rollups for late delivery, low-review, cancellation/unavailable status, order volume, and value.
4. Produce review-prioritization outputs for orders, sellers, routes, categories, low-review patterns, and payment/installment patterns.
5. Write generated CSV outputs and a markdown summary under `case_studies/olist_marketplace_integrity/results/`.

## Interpretation

Flags should be read as leads, not conclusions. Shared payment or device fingerprints can reflect household, enterprise, reseller, or operational reuse. A country mismatch can reflect travel, resale, logistics, or data quality. The point of the queue is to prioritize review, not automate enforcement.

The Olist dataset does not provide confirmed fraud or abuse labels. Olist outputs are marketplace integrity signals, not fraud findings.
