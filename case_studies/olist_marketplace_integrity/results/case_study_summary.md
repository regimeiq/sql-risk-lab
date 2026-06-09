# Olist Marketplace Integrity Case Study Results

Source: Olist Brazilian E-Commerce Public Dataset.

These outputs use public marketplace data to demonstrate SQL-based review prioritization. The dataset does not provide confirmed fraud or abuse labels, so scores should be read as operational review signals only.

## Dataset Profile

| table_name | row_count |
| --- | --- |
| customers | 99441 |
| geolocation | 1000163 |
| order_items | 112650 |
| order_payments | 103886 |
| order_reviews | 99224 |
| orders | 99441 |
| product_category_translation | 71 |
| products | 32951 |
| sellers | 3095 |


## Case Metrics

| metric | value |
| --- | --- |
| orders_total | 99441 |
| queued_orders_medium_plus | 8349 |
| queued_orders_critical | 18 |
| queued_orders_high | 2985 |
| queued_orders_medium | 5346 |
| queued_orders_low_review | 7905 |
| queued_orders_canceled_or_unavailable | 1234 |
| queued_orders_very_late_delivery | 2730 |
| queued_orders_high_installments | 1133 |
| sellers_total | 3095 |
| sellers_with_20plus_orders | 818 |
| sellers_high_priority | 1 |
| sellers_medium_priority | 39 |


## Top Order Review Queue

| order_id | customer_state | seller_states | categories | order_status | order_purchase_timestamp | delivered_customer_date | estimated_delivery_date | item_count | seller_count | total_item_value | total_freight_value | total_payment_value | max_payment_installments | min_review_score | priority_score | priority_band | risk_flags |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 078f6a01964ee122ef20881df839af31 | PR | SP | home_appliances_2 | canceled | 2018-08-06 11:06:21 |  | 2018-08-16 00:00:00 | 1 | 1 | 2350.0 | 69.2 | 2419.2 | 10 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_installments\|high_value_order\|low_review_with_comment |
| 2aaab7e991347226dbda1f61c6785f88 | SP | SP | baby | canceled | 2018-07-25 13:57:52 |  | 2018-08-10 00:00:00 | 5 | 1 | 49.95 | 36.949999999999996 | 86.9 | 1 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_freight_ratio\|high_item_count\|low_review_with_comment |
| a9c8ac0c26c178f0ad33618f96225a01 | PR | PR | electronics | canceled | 2018-07-22 23:36:14 |  | 2018-08-07 00:00:00 | 5 | 1 | 1795.0 | 155.2 | 1950.2 | 8 | 2 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_item_count\|high_value_order\|low_review_with_comment |
| b85825cdbdab14cc17f2e159f0fba217 | SP | SP | baby | canceled | 2018-07-21 23:27:59 |  | 2018-08-09 00:00:00 | 1 | 1 | 112.0 | 62.86 | 174.86 | 10 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_installments\|high_freight_ratio\|low_review_with_comment |
| f7b13a5afd48ca5bcf589a25d5377b00 | MG | SP | cool_stuff | canceled | 2018-07-12 12:14:56 |  | 2018-07-30 00:00:00 | 1 | 1 | 2299.95 | 104.77 | 2404.72 | 10 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_installments\|high_value_order\|low_review_with_comment |
| 266f9c3f364a7ef351edb998487ae783 | MT | SP | perfumery | delivered | 2018-03-05 12:30:40 | 2018-04-04 19:03:02 | 2018-03-28 00:00:00 | 6 | 1 | 63.599999999999994 | 100.74 | 164.34 | 10 | 1 | 85 | Critical | very_late_delivery\|low_review_score\|high_installments\|high_freight_ratio\|high_item_count\|low_review_with_comment |
| 808c7c69c2778bdf4689eee0286e2bef | SP | SP | furniture_decor | canceled | 2018-02-22 07:57:07 |  | 2018-03-13 00:00:00 | 6 | 1 | 77.94 | 56.04 | 133.98 | 1 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_freight_ratio\|high_item_count\|low_review_with_comment |
| 0148d3df00cebda592d4e5f966e300cc | SP | SP | housewares | canceled | 2017-08-19 19:08:26 |  | 2017-09-11 00:00:00 | 5 | 1 | 27.650000000000002 | 59.25 | 86.9 | 1 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_freight_ratio\|high_item_count\|low_review_with_comment |
| be3b8d058b8100d8a2539ce0b2c6ec0b | RJ | SP | watches_gifts | canceled | 2017-07-20 14:32:34 |  | 2017-08-11 00:00:00 | 1 | 1 | 1199.9 | 23.16 | 1223.06 | 10 | 2 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_installments\|high_value_order\|low_review_with_comment |
| e23eaa3bc8275c392145e736dbdea275 | SP | SP | auto | canceled | 2017-06-18 17:22:09 |  | 2017-06-30 00:00:00 | 1 | 1 | 1999.99 | 26.55 | 2026.54 | 10 | 1 | 85 | Critical | canceled_or_unavailable\|low_review_score\|high_installments\|high_value_order\|low_review_with_comment |


## Top Seller Integrity Rollup

| seller_id | seller_state | order_count | delivered_order_count | canceled_or_unavailable_count | late_delivery_count | very_late_count | low_review_count | total_item_value | avg_review_score | late_delivery_rate | low_review_rate | cancellation_rate | seller_priority_score | seller_priority_band |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ede0c03645598cdfc63ca8237acbe73d | SP | 46 | 43 | 1 | 15 | 10 | 13 | 2518.37 | 3.522727272727273 | 0.326 | 0.283 | 0.022 | 65 | High |
| 7c67e1448b00f6e969d365cea6b010ab | SP | 982 | 973 | 0 | 98 | 49 | 253 | 187923.89 | 3.4836065573770494 | 0.1 | 0.258 | 0.0 | 50 | Medium |
| cca3071e3e9bb7d12640c9fbe2301306 | SP | 712 | 699 | 1 | 41 | 18 | 144 | 64009.89 | 3.835714285714286 | 0.058 | 0.202 | 0.001 | 50 | Medium |
| d2374cbcbb3ca4ab1086534108cc3ab7 | SP | 524 | 514 | 1 | 30 | 10 | 108 | 21223.92 | 3.749034749034749 | 0.057 | 0.206 | 0.002 | 50 | Medium |
| 1835b56ce799e6a4dc4eddc053f04066 | SP | 423 | 417 | 0 | 49 | 23 | 104 | 33344.21 | 3.630952380952381 | 0.116 | 0.246 | 0.0 | 50 | Medium |
| 897060da8b9a21f655304d50fd935913 | SP | 317 | 304 | 1 | 36 | 17 | 82 | 23023.92 | 3.621019108280255 | 0.114 | 0.259 | 0.003 | 50 | Medium |
| 70a12e78e608ac31179aea7f8422044b | SP | 315 | 312 | 0 | 34 | 16 | 63 | 30858.53 | 3.7987220447284344 | 0.108 | 0.2 | 0.0 | 50 | Medium |
| 855668e0971d4dfd7bef1b6a4133b41b | SP | 312 | 300 | 2 | 42 | 23 | 70 | 32208.16 | 3.771986970684039 | 0.135 | 0.224 | 0.006 | 50 | Medium |
| 88460e8ebdecbfecb5f9601833981930 | PR | 248 | 246 | 1 | 48 | 27 | 78 | 31546.550000000003 | 3.4048582995951415 | 0.194 | 0.315 | 0.004 | 50 | Medium |
| c3867b4666c7d76867627c2f7fb22e21 | SP | 245 | 228 | 5 | 27 | 17 | 50 | 37153.4 | 3.905349794238683 | 0.11 | 0.204 | 0.02 | 50 | Medium |


## Late Delivery Routes

| customer_state | seller_state | order_count | late_delivery_count | avg_days_late_when_late | late_delivery_rate | avg_review_score |
| --- | --- | --- | --- | --- | --- | --- |
| AL | PR | 35 | 14 | 10.9 | 0.4 | 3.54 |
| AL | SP | 254 | 67 | 9.1 | 0.264 | 3.71 |
| SP | MA | 123 | 31 | 7.4 | 0.252 | 3.93 |
| CE | RJ | 54 | 12 | 19.7 | 0.222 | 3.65 |
| MA | SP | 486 | 104 | 9.7 | 0.214 | 3.72 |
| MA | PR | 40 | 8 | 7.2 | 0.2 | 3.88 |
| PI | SP | 327 | 60 | 13.7 | 0.183 | 3.97 |
| AL | MG | 35 | 6 | 5.5 | 0.171 | 4.15 |
| BA | PR | 143 | 24 | 15.9 | 0.168 | 3.82 |
| MA | MG | 60 | 10 | 6.5 | 0.167 | 4.37 |


## Low Review Patterns

| customer_state | categories | order_status | order_count | low_review_count | low_review_rate | avg_days_late | avg_item_value |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SP | sports_leisure | canceled | 28 | 25 | 0.893 |  | 146.11 |
| MG | unknown | unavailable | 71 | 63 | 0.887 |  |  |
| RJ | unknown | unavailable | 66 | 58 | 0.879 |  |  |
| SP | unknown | unavailable | 283 | 243 | 0.859 |  |  |
| PR | unknown | unavailable | 40 | 30 | 0.75 |  |  |
| SP | health_beauty | shipped | 28 | 20 | 0.714 |  | 69.13 |
| RJ | bed_bath_table | shipped | 30 | 20 | 0.667 |  | 108.09 |
| SP | bed_bath_table | shipped | 40 | 26 | 0.65 |  | 100.09 |
| SP | sports_leisure | shipped | 26 | 16 | 0.615 |  | 130.0 |
| SP | unknown | canceled | 88 | 49 | 0.557 |  | 53.18 |


## Interpretation Notes

- Late fulfillment, low reviews, high installment counts, and high freight ratios are review signals, not proof of misuse.
- Seller-level scoring is useful for prioritizing operational review, partner-quality checks, and customer-impact analysis.
- The synthetic SQL Risk Lab remains the better place to demonstrate explicit fraud, abuse, diversion, and fake-watchlist scenarios.
