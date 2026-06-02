# Olist Marketplace Integrity Case Study

This companion case study applies the SQL Risk Lab workflow to the public Olist Brazilian E-Commerce dataset. The goal is to show the same kind of practical SQL analysis on real, anonymized marketplace data without treating the dataset as a fraud ground truth.

## Dataset

Source: [Olist Brazilian E-Commerce Public Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The raw CSVs are not committed by default. Place them in:

```text
case_studies/olist_marketplace_integrity/data/raw/
```

Required files:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

## Framing

Olist is useful here because it has orders, sellers, customers, payments, delivery timestamps, reviews, product categories, and geography. It does not provide confirmed fraud labels, sanctions signals, platform abuse reports, or investigative outcomes.

This case study therefore focuses on marketplace integrity indicators:

- Late or failed fulfillment.
- Low-review orders with delivery or support friction.
- Seller concentration and seller quality signals.
- Multi-seller orders and shipping complexity.
- Payment and installment patterns.
- Review queue logic for prioritizing manual marketplace review.

Scores are triage aids, not conclusions.

## Run

After placing the raw CSV files:

```bash
python3 scripts/run_olist_case_study.py
```

Outputs are written to:

```text
case_studies/olist_marketplace_integrity/results/
```

Start with [results/case_study_summary.md](results/case_study_summary.md) for the case narrative and [results/README.md](results/README.md) for output definitions.

The runner creates a local SQLite database at:

```text
case_studies/olist_marketplace_integrity/data/olist_marketplace.sqlite
```

## Output Files

- `01_dataset_profile.csv`
- `02_order_integrity_queue.csv`
- `03_seller_integrity_rollup.csv`
- `04_late_delivery_by_route.csv`
- `05_low_review_patterns.csv`
- `06_payment_pattern_review.csv`
- `07_category_fulfillment_risk.csv`
- `08_case_study_metrics.csv`
- `case_study_summary.md`

## Portfolio Use

Use SQL Risk Lab as the controlled synthetic scenario engine. Use this Olist case study as the real-data appendix showing that the same analyst workflow can be applied to a public marketplace dataset.
