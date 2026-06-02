# Case Walkthroughs

These walkthroughs show how raw rows become reviewable signals. They are not
fraud findings, sanctions findings, or enforcement decisions. The pattern is:

1. Question
2. SQL pattern
3. Representative output
4. Interpretation
5. False-positive and limitation notes

## 1. Synthetic Asset Diversion Path

### Question

Which synthetic assets were shipped through a low-risk path but later transferred
or activated in a higher-risk synthetic geography?

### SQL Pattern

The query starts from the asset lifecycle view, then compares shipment risk
against first-transfer and latest-activation risk. The review condition is a
low-risk shipment combined with a high-risk or restricted later state.

```sql
SELECT
    tl.asset_id,
    tl.order_id,
    tl.purchaser_account_id,
    tl.shipping_country_code,
    tl.shipping_risk_tier,
    tl.first_transfer_ts,
    tl.first_transfer_to_account_id,
    tl.latest_activation_country_code,
    tl.latest_activation_risk_tier,
    tl.latest_activation_is_restricted
FROM v_asset_lifecycle tl
LEFT JOIN countries transfer_country
  ON transfer_country.country_code = tl.first_transfer_country_code
WHERE tl.shipping_risk_tier <= 2
  AND (
        tl.latest_activation_risk_tier >= 4
     OR tl.latest_activation_is_restricted
     OR transfer_country.risk_tier >= 4
      );
```

Full query: [11_diversion_style_movement_paths.sql](../sql/queries/11_diversion_style_movement_paths.sql)

### Representative Output

Synthetic entity: `ASSET-0000127`

| Field | Value |
|---|---|
| Original order | `ORD-0000096` |
| Purchaser account | `ACCT-000042` |
| Order timestamp | `2025-11-26 10:09:11` |
| Shipped to | `C02` / `Greenhaven` |
| Shipping risk tier | `1` |
| First transfer | `2025-12-01 22:09:11` |
| Transfer path | `ACCT-000042` to `ACCT-000144` |
| Transfer reason | `resale` |
| Latest activation | `2025-12-08 22:09:11` |
| Activation country | `C09` / `Red Mesa Directorate` |
| Activation risk tier | `5` |

### Interpretation

This is a clean synthetic example of a diversion-style review pattern: a
legal-looking purchase and shipment path followed by rapid transfer and
activation in a restricted or high-risk synthetic geography. The useful signal
is not any one field. It is the sequence: low-risk fulfillment, quick ownership
change, then high-risk activation.

### False-Positive And Limitation Notes

- The countries, accounts, and watchlist concepts are invented.
- Transfer after purchase can be legitimate: resale, gifting, warranty exchange,
  enterprise reassignment, or household transfer.
- The SQL surfaces review candidates. A real review would need customer history,
  device entitlement rules, payment context, and policy-specific controls.
- The score does not establish misconduct. It only prioritizes records for human
  review.

## 2. Olist Critical Order Review

### Question

Which public marketplace orders combine customer-impact signals strongly enough
to deserve operational review?

### SQL Pattern

The Olist queue selects from a review view and sorts by priority score. The
scoring inputs include fulfillment status, review score, order value, payment
installments, freight ratio, item count, and review-comment signals.

```sql
SELECT
    order_id,
    customer_state,
    seller_states,
    categories,
    order_status,
    total_item_value,
    total_payment_value,
    max_payment_installments,
    min_review_score,
    priority_score,
    priority_band,
    risk_flags
FROM v_order_integrity_queue
ORDER BY priority_score DESC, order_purchase_timestamp DESC
LIMIT 100;
```

Full query: [02_order_integrity_queue.sql](../case_studies/olist_marketplace_integrity/sql/queries/02_order_integrity_queue.sql)

### Representative Output

Public Olist order: `078f6a01964ee122ef20881df839af31`

| Field | Value |
|---|---|
| Customer state | `PR` |
| Seller state | `SP` |
| Category | `home_appliances_2` |
| Status | `canceled` |
| Item value | `2350.00` |
| Freight value | `69.20` |
| Payment value | `2419.20` |
| Installments | `10` |
| Minimum review score | `1` |
| Priority score | `85` |
| Priority band | `Critical` |
| Flags | `canceled_or_unavailable`, `low_review_score`, `high_installments`, `high_value_order`, `low_review_with_comment` |

Relevant output: [02_order_integrity_queue.csv](../case_studies/olist_marketplace_integrity/results/02_order_integrity_queue.csv)

### Interpretation

This record is a marketplace-integrity review candidate because cancellation,
high value, high installments, and a low review score combine into a meaningful
customer-impact signal. The case is useful for prioritization because multiple
independent operational signals point to the same order.

### False-Positive And Limitation Notes

- The Olist dataset does not contain fraud labels.
- A canceled high-value order is not evidence of abuse by itself.
- Low reviews can reflect shipping delay, product quality, stock issues,
  customer misunderstanding, or carrier problems.
- The correct conclusion is "review priority," not "fraud," "seller abuse," or
  "policy violation."

## 3. Olist Seller Integrity Rollup

### Question

Which sellers have enough order volume and customer-impact signals to support
seller-level operational review?

### SQL Pattern

The seller rollup aggregates order count, delivery status, late delivery,
low-review outcomes, cancellation/unavailability, item value, and rates. It
filters out very small sellers so a few bad orders do not dominate the queue.

```sql
SELECT
    seller_id,
    seller_state,
    order_count,
    delivered_order_count,
    late_delivery_count,
    very_late_count,
    low_review_count,
    avg_review_score,
    late_delivery_rate,
    low_review_rate,
    seller_priority_score,
    seller_priority_band
FROM v_seller_integrity_rollup
WHERE order_count >= 20
ORDER BY seller_priority_score DESC, order_count DESC
LIMIT 100;
```

Full query: [03_seller_integrity_rollup.sql](../case_studies/olist_marketplace_integrity/sql/queries/03_seller_integrity_rollup.sql)

### Representative Output

Public Olist seller: `ede0c03645598cdfc63ca8237acbe73d`

| Field | Value |
|---|---|
| Seller state | `SP` |
| Orders | `46` |
| Delivered orders | `43` |
| Canceled or unavailable | `1` |
| Late deliveries | `15` |
| Very late deliveries | `10` |
| Low-review orders | `13` |
| Average review score | `3.52` |
| Late delivery rate | `0.326` |
| Low-review rate | `0.283` |
| Seller priority score | `65` |
| Seller priority band | `High` |

Relevant output: [03_seller_integrity_rollup.csv](../case_studies/olist_marketplace_integrity/results/03_seller_integrity_rollup.csv)

### Interpretation

This is a seller-quality review candidate. The pattern combines non-trivial
volume with elevated late-delivery and low-review rates. In a real marketplace,
this could support partner-quality review, fulfillment follow-up, routing
analysis, or customer-impact monitoring.

### False-Positive And Limitation Notes

- Seller-level signals can be driven by carrier issues, geography, category mix,
  seasonality, stockouts, or marketplace operations outside the seller's control.
- A `High` seller priority band does not mean seller misconduct.
- The rollup is a queueing layer. It points a reviewer toward a pattern and
  supporting rows; it does not complete the investigation.
- Stronger review would require policy labels, carrier context, refund outcomes,
  customer-contact history, and seller operational data.
