# Data Dictionary

This dictionary covers the synthetic SQL Risk Lab schema. The Olist companion case study uses the public Olist CSV schema and derived SQLite views documented in [`case_studies/olist_marketplace_integrity/sql/00_build_views.sql`](../case_studies/olist_marketplace_integrity/sql/00_build_views.sql).

## Reference Tables

### `countries`

Fake countries with synthetic region, risk tier, and restricted status.

### `shipping_nodes`

Fake fulfillment or logistics nodes linked to synthetic countries.

### `reseller_profiles`

Fake reseller records used to model partner, broker, and marketplace flows.

### `watchlist_entities`

Fake watchlist entries. `entity_type` describes the field to match, and `entity_value` stores the synthetic value.

## Core Entity Tables

### `accounts`

Synthetic account records with fingerprinted identifiers: email, phone, payment, device, shipping address, support language, reseller relationship, and acquisition channel.

### `orders`

Order headers with account, channel, shipping country, shipping node, payment fingerprint, device fingerprint, value, asset count, and status.

### `order_items`

Asset-level order lines connecting orders to assets.

### `assets`

Synthetic asset inventory with model, serial number, first order, current account, and current status.

## Event Tables

### `activations`

Asset activation events with account, activation country, region, IP fingerprint, and device fingerprint.

### `asset_transfers`

Movement of an asset from one account to another, including transfer reason and transfer country.

### `support_tickets`

Support interactions tied to account and optionally asset, with reason, language, country, and message fingerprint.

### `abuse_reports`

Misuse reports tied to account and optionally asset, with severity and fake narrative fingerprint.

### `chargebacks`

Payment disputes linked to order and account with reason, amount, and dispute status.

## Derived Synthetic Views

### `v_latest_asset_activation`

Latest activation event per asset using a window function.

### `v_identifier_clusters`

Reusable identifier clusters across accounts for payment, device, phone, email, shipping address, support language, and reseller values.

### `v_order_bursts`

Rolling 24-hour order windows used to identify bulk-order patterns.

### `v_asset_lifecycle`

Asset purchase, shipping, activation, and first-transfer context in one view.

### `v_account_risk_flags`

Account-level feature view used for scoring.

### `v_asset_risk_flags`

Asset-level feature view used for scoring.

### `v_review_queue`

Combined account and asset review queue with priority score, priority band, risk flags, and supporting facts.
