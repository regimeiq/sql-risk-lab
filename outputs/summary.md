# SQL Risk Lab Outputs Summary

This project has two output tracks:

- Synthetic PostgreSQL lab outputs for controlled risk scenarios.
- Olist marketplace integrity outputs generated from a public real-world marketplace dataset.

The synthetic lab is designed to demonstrate explicit fraud, abuse, diversion-style movement, shared-identifier, chargeback, and fake-watchlist patterns using public-safe generated data. The Olist companion case study demonstrates the same review-queue workflow on public marketplace data, framed as operational integrity rather than fraud labeling.

## Synthetic Lab Outputs

Primary output:

- `review_queue`: materialized PostgreSQL review queue produced by [`sql/30_review_queue.sql`](../sql/30_review_queue.sql).

Supporting SQL:

- [`sql/20_views.sql`](../sql/20_views.sql): latest activation, identifier clusters, order bursts, asset lifecycle, account flags, asset flags, and review queue view.
- [`sql/queries/`](../sql/queries/): 15 analyst queries covering profiling, shared identifiers, bulk ordering, rapid transfers, abuse reports, chargebacks, watchlist hits, diversion-style movement, lifecycle timelines, support clustering, and score explainability.

Generated data:

- Public-safe synthetic CSVs live under [`data/generated/`](../data/generated/).
- Validation is handled by [`scripts/validate_generated_data.py`](../scripts/validate_generated_data.py).

## Olist Case Study Outputs

Generated outputs live under [`case_studies/olist_marketplace_integrity/results/`](../case_studies/olist_marketplace_integrity/results/).

Current case-study metrics:

- `99,441` public marketplace orders.
- `3,095` sellers.
- `8,349` medium-plus queued orders.
- `18` critical queued orders.
- `14` high-priority sellers.
- `266` medium-priority sellers.

Key files:

- [`01_dataset_profile.csv`](../case_studies/olist_marketplace_integrity/results/01_dataset_profile.csv): table row counts.
- [`02_order_integrity_queue.csv`](../case_studies/olist_marketplace_integrity/results/02_order_integrity_queue.csv): top queued order-level review candidates.
- [`03_seller_integrity_rollup.csv`](../case_studies/olist_marketplace_integrity/results/03_seller_integrity_rollup.csv): seller-level integrity rollup.
- [`04_late_delivery_by_route.csv`](../case_studies/olist_marketplace_integrity/results/04_late_delivery_by_route.csv): seller-state to customer-state route risk.
- [`05_low_review_patterns.csv`](../case_studies/olist_marketplace_integrity/results/05_low_review_patterns.csv): low-review concentrations by state, category, and status.
- [`06_payment_pattern_review.csv`](../case_studies/olist_marketplace_integrity/results/06_payment_pattern_review.csv): payment type and installment patterns.
- [`07_category_fulfillment_risk.csv`](../case_studies/olist_marketplace_integrity/results/07_category_fulfillment_risk.csv): category-level fulfillment and review risk.
- [`08_case_study_metrics.csv`](../case_studies/olist_marketplace_integrity/results/08_case_study_metrics.csv): aggregate output metrics.
- [`case_study_summary.md`](../case_studies/olist_marketplace_integrity/results/case_study_summary.md): generated markdown summary of the case study.

## Interpretation

Review queues are prioritization tools. They are not findings of fraud, abuse, sanctions exposure, or policy violation. The synthetic lab intentionally contains injected risk scenarios. The Olist dataset does not include confirmed fraud or abuse labels, so Olist outputs should be read as marketplace integrity signals only.

