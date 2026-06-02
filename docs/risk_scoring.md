# Risk Scoring

Risk scoring in this lab is transparent and SQL-based. Each entity receives weighted flags. The total score determines queue priority.

## Account-Level Signals

- Shared payment fingerprint across three or more accounts.
- Shared device fingerprint across three or more accounts.
- Shared phone fingerprint across three or more accounts.
- Shared shipping address fingerprint across three or more accounts.
- Bulk order activity within a 24-hour window.
- Multiple chargebacks or high chargeback rate.
- Repeated abuse reports.
- Signup country or identifier hit on a fake watchlist.
- Watchlisted reseller relationship.

## Asset-Level Signals

- Shipped to one country and activated in another.
- Activated in a fake restricted country.
- Transferred within 14 days of purchase.
- Activated by multiple accounts.
- Repeated abuse reports.
- Chargeback associated with original order.
- Movement from low-risk purchase path into high-risk or restricted synthetic geography.

## Priority Bands

- `Critical`: score >= 90
- `High`: score >= 60 and < 90
- `Medium`: score >= 35 and < 60
- `Low`: score < 35

Only `Medium` and above are materialized into the default `review_queue` table.

## Review Guidance

The score should answer: "What should an analyst review first?" It should not answer: "What action should be taken?" Any decision would require additional context, quality checks, policy review, and appropriate human judgment.

