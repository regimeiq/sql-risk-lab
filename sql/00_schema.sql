DROP TABLE IF EXISTS review_queue CASCADE;
DROP TABLE IF EXISTS chargebacks CASCADE;
DROP TABLE IF EXISTS abuse_reports CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS asset_transfers CASCADE;
DROP TABLE IF EXISTS activations CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS assets CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS reseller_profiles CASCADE;
DROP TABLE IF EXISTS shipping_nodes CASCADE;
DROP TABLE IF EXISTS watchlist_entities CASCADE;
DROP TABLE IF EXISTS countries CASCADE;

CREATE TABLE countries (
    country_code VARCHAR(8) PRIMARY KEY,
    country_name TEXT NOT NULL UNIQUE,
    region TEXT NOT NULL,
    risk_tier INTEGER NOT NULL CHECK (risk_tier BETWEEN 1 AND 5),
    is_restricted BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT
);

CREATE TABLE watchlist_entities (
    watchlist_id VARCHAR(20) PRIMARY KEY,
    entity_type TEXT NOT NULL CHECK (
        entity_type IN (
            'country_code',
            'reseller_id',
            'email_domain',
            'payment_fingerprint',
            'device_fingerprint',
            'shipping_address_fingerprint',
            'phone_fingerprint',
            'account_id'
        )
    ),
    entity_value TEXT NOT NULL,
    entity_label TEXT NOT NULL,
    risk_tier INTEGER NOT NULL CHECK (risk_tier BETWEEN 1 AND 5),
    reason_code TEXT NOT NULL,
    active_from DATE NOT NULL,
    active_to DATE,
    source_note TEXT NOT NULL,
    UNIQUE (entity_type, entity_value, active_from)
);

CREATE TABLE shipping_nodes (
    shipping_node_id VARCHAR(16) PRIMARY KEY,
    node_name TEXT NOT NULL,
    node_country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    node_type TEXT NOT NULL CHECK (
        node_type IN ('fulfillment_center', 'reseller_drop_ship', 'returns_hub', 'marketplace_node')
    ),
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE reseller_profiles (
    reseller_id VARCHAR(16) PRIMARY KEY,
    reseller_name TEXT NOT NULL,
    registered_country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    reseller_tier TEXT NOT NULL CHECK (
        reseller_tier IN ('standard', 'preferred', 'marketplace', 'watch_review')
    ),
    status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'terminated', 'review')),
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE accounts (
    account_id VARCHAR(16) PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    account_type TEXT NOT NULL CHECK (account_type IN ('individual', 'business', 'reseller')),
    signup_country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    email_fingerprint TEXT NOT NULL,
    email_domain TEXT NOT NULL,
    phone_fingerprint TEXT NOT NULL,
    payment_fingerprint TEXT NOT NULL,
    device_fingerprint TEXT NOT NULL,
    shipping_address_fingerprint TEXT NOT NULL,
    support_language TEXT NOT NULL,
    reseller_id VARCHAR(16) REFERENCES reseller_profiles(reseller_id),
    acquisition_channel TEXT NOT NULL CHECK (
        acquisition_channel IN ('organic_web', 'paid_search', 'partner_portal', 'marketplace', 'support_assisted')
    ),
    status TEXT NOT NULL CHECK (status IN ('active', 'limited', 'closed', 'under_review')),
    synthetic_segment TEXT NOT NULL
);

CREATE TABLE orders (
    order_id VARCHAR(16) PRIMARY KEY,
    account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    order_ts TIMESTAMP NOT NULL,
    order_channel TEXT NOT NULL CHECK (
        order_channel IN ('web', 'partner_portal', 'marketplace', 'support_assisted', 'api')
    ),
    shipping_country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    shipping_node_id VARCHAR(16) NOT NULL REFERENCES shipping_nodes(shipping_node_id),
    shipping_address_fingerprint TEXT NOT NULL,
    payment_fingerprint TEXT NOT NULL,
    device_fingerprint TEXT NOT NULL,
    order_value_usd NUMERIC(12,2) NOT NULL CHECK (order_value_usd >= 0),
    asset_count INTEGER NOT NULL CHECK (asset_count > 0),
    order_status TEXT NOT NULL CHECK (order_status IN ('paid', 'fulfilled', 'cancelled', 'refunded')),
    synthetic_scenario TEXT NOT NULL
);

CREATE TABLE assets (
    asset_id VARCHAR(16) PRIMARY KEY,
    serial_number TEXT NOT NULL UNIQUE,
    model TEXT NOT NULL,
    manufactured_at DATE NOT NULL,
    first_order_id VARCHAR(16) NOT NULL REFERENCES orders(order_id),
    current_account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    current_status TEXT NOT NULL CHECK (current_status IN ('in_stock', 'shipped', 'active', 'transferred', 'disabled')),
    synthetic_scenario TEXT NOT NULL
);

CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(16) NOT NULL REFERENCES orders(order_id),
    asset_id VARCHAR(16) NOT NULL UNIQUE REFERENCES assets(asset_id),
    unit_price_usd NUMERIC(12,2) NOT NULL CHECK (unit_price_usd >= 0)
);

CREATE TABLE activations (
    activation_id VARCHAR(20) PRIMARY KEY,
    asset_id VARCHAR(16) NOT NULL REFERENCES assets(asset_id),
    account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    activation_ts TIMESTAMP NOT NULL,
    activation_country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    activation_region TEXT NOT NULL,
    ip_fingerprint TEXT NOT NULL,
    device_fingerprint TEXT NOT NULL
);

CREATE TABLE asset_transfers (
    transfer_id VARCHAR(20) PRIMARY KEY,
    asset_id VARCHAR(16) NOT NULL REFERENCES assets(asset_id),
    from_account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    to_account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    transfer_ts TIMESTAMP NOT NULL,
    transfer_reason TEXT NOT NULL CHECK (
        transfer_reason IN ('resale', 'support_replacement', 'business_reassignment', 'unknown', 'marketplace_transfer')
    ),
    initiated_by TEXT NOT NULL CHECK (initiated_by IN ('account_holder', 'support_agent', 'reseller_portal', 'system')),
    transfer_country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code)
);

CREATE TABLE support_tickets (
    ticket_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    asset_id VARCHAR(16) REFERENCES assets(asset_id),
    opened_at TIMESTAMP NOT NULL,
    support_language TEXT NOT NULL,
    reason_code TEXT NOT NULL CHECK (
        reason_code IN ('activation_help', 'billing_dispute', 'transfer_request', 'device_issue', 'policy_question')
    ),
    country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    message_fingerprint TEXT NOT NULL
);

CREATE TABLE abuse_reports (
    report_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(16) REFERENCES accounts(account_id),
    asset_id VARCHAR(16) REFERENCES assets(asset_id),
    report_ts TIMESTAMP NOT NULL,
    report_type TEXT NOT NULL CHECK (
        report_type IN ('misuse_report', 'chargeback_abuse', 'policy_evasion', 'unsafe_resale', 'identity_concern')
    ),
    reporter_type TEXT NOT NULL CHECK (reporter_type IN ('customer', 'internal', 'partner', 'automated')),
    country_code VARCHAR(8) NOT NULL REFERENCES countries(country_code),
    severity INTEGER NOT NULL CHECK (severity BETWEEN 1 AND 5),
    narrative_fingerprint TEXT NOT NULL,
    CHECK (account_id IS NOT NULL OR asset_id IS NOT NULL)
);

CREATE TABLE chargebacks (
    chargeback_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(16) NOT NULL REFERENCES orders(order_id),
    account_id VARCHAR(16) NOT NULL REFERENCES accounts(account_id),
    chargeback_ts TIMESTAMP NOT NULL,
    reason_code TEXT NOT NULL CHECK (
        reason_code IN ('fraudulent', 'product_not_received', 'duplicate', 'subscription_dispute', 'unknown')
    ),
    amount_usd NUMERIC(12,2) NOT NULL CHECK (amount_usd >= 0),
    dispute_status TEXT NOT NULL CHECK (dispute_status IN ('open', 'won', 'lost', 'withdrawn'))
);

CREATE INDEX idx_accounts_identifiers ON accounts (
    payment_fingerprint,
    device_fingerprint,
    phone_fingerprint,
    shipping_address_fingerprint
);
CREATE INDEX idx_accounts_reseller ON accounts(reseller_id);
CREATE INDEX idx_orders_account_ts ON orders(account_id, order_ts);
CREATE INDEX idx_orders_shipping ON orders(shipping_country_code, shipping_node_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_activations_asset_ts ON activations(asset_id, activation_ts DESC);
CREATE INDEX idx_activations_country_ts ON activations(activation_country_code, activation_ts DESC);
CREATE INDEX idx_transfers_asset_ts ON asset_transfers(asset_id, transfer_ts);
CREATE INDEX idx_abuse_account_ts ON abuse_reports(account_id, report_ts DESC);
CREATE INDEX idx_abuse_asset_ts ON abuse_reports(asset_id, report_ts DESC);
CREATE INDEX idx_chargebacks_account_ts ON chargebacks(account_id, chargeback_ts DESC);
CREATE INDEX idx_watchlist_lookup ON watchlist_entities(entity_type, entity_value);

