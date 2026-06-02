# Case Walkthroughs

These walkthroughs are short examples of how the project turns raw records into reviewable risk signals. They are not enforcement decisions.

## 1. Synthetic Asset Diversion Path

Synthetic entity: `ASSET-0000127`

Why it queued:

- Original order `ORD-0000096` was placed by `ACCT-000042` on `2025-11-26 10:09:11`.
- The asset shipped to `C02` / `Greenhaven`, a fake low-risk synthetic country with risk tier `1`.
- The asset transferred five days later on `2025-12-01 22:09:11`.
- Transfer path: `ACCT-000042` to `ACCT-000144`.
- Transfer reason: `resale`.
- Latest activation occurred on `2025-12-08 22:09:11`.
- Activation country was `C09` / `Red Mesa Directorate`, a fake restricted synthetic country with risk tier `5`.

Review interpretation:

This is a clean synthetic example of the lab's diversion-style pattern: a legal-looking purchase and shipment path followed by rapid transfer and activation in a restricted/high-risk synthetic geography. The signal is intentionally framed for analyst review, not automated action.

Relevant query:

- [11_diversion_style_movement_paths.sql](../sql/queries/11_diversion_style_movement_paths.sql)

## 2. Olist Critical Order Review

Public Olist order: `078f6a01964ee122ef20881df839af31`

Why it queued:

- Customer state: `PR`.
- Seller state: `SP`.
- Category: `home_appliances_2`.
- Order status: `canceled`.
- Order value: `2350.00`.
- Freight value: `69.20`.
- Payment value: `2419.20`.
- Installments: `10`.
- Minimum review score: `1`.
- Priority score: `85`.
- Priority band: `Critical`.
- Risk flags: `canceled_or_unavailable`, `low_review_score`, `high_installments`, `high_value_order`, `low_review_with_comment`.

Review interpretation:

The dataset does not prove fraud or abuse. This record is a marketplace-integrity review candidate because cancellation, high value, high installments, and a low review score combine into a customer-impact signal.

Relevant outputs:

- [02_order_integrity_queue.csv](../case_studies/olist_marketplace_integrity/results/02_order_integrity_queue.csv)
- [case_study_summary.md](../case_studies/olist_marketplace_integrity/results/case_study_summary.md)

## 3. Olist Seller Integrity Rollup

Public Olist seller: `ede0c03645598cdfc63ca8237acbe73d`

Why it queued:

- Seller state: `SP`.
- Orders: `46`.
- Delivered orders: `43`.
- Late deliveries: `15`.
- Very late deliveries: `10`.
- Low-review orders: `13`.
- Average review score: `3.52`.
- Late delivery rate: `0.326`.
- Low-review rate: `0.283`.
- Seller priority score: `65`.
- Seller priority band: `High`.

Review interpretation:

This is a seller-quality review candidate. The pattern combines a meaningful order count with elevated late-delivery and low-review rates. In a real environment, this would support operational review, partner-quality follow-up, or customer-impact analysis.

Relevant outputs:

- [03_seller_integrity_rollup.csv](../case_studies/olist_marketplace_integrity/results/03_seller_integrity_rollup.csv)
