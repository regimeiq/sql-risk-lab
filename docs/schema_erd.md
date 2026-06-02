# Schema ERD

This diagram shows the synthetic SQL Risk Lab schema. The Olist companion case study has a separate public dataset schema under `case_studies/olist_marketplace_integrity/`.

```mermaid
erDiagram
    COUNTRIES ||--o{ ACCOUNTS : signup_country
    COUNTRIES ||--o{ SHIPPING_NODES : node_country
    COUNTRIES ||--o{ ORDERS : shipping_country
    COUNTRIES ||--o{ ACTIVATIONS : activation_country
    COUNTRIES ||--o{ ASSET_TRANSFERS : transfer_country
    COUNTRIES ||--o{ SUPPORT_TICKETS : support_country
    COUNTRIES ||--o{ ABUSE_REPORTS : report_country

    RESELLER_PROFILES ||--o{ ACCOUNTS : reseller
    ACCOUNTS ||--o{ ORDERS : places
    SHIPPING_NODES ||--o{ ORDERS : fulfills
    ORDERS ||--o{ ORDER_ITEMS : contains
    ORDERS ||--o{ CHARGEBACKS : disputed_by
    ORDER_ITEMS ||--|| ASSETS : assigns
    ACCOUNTS ||--o{ ASSETS : current_holder
    ASSETS ||--o{ ACTIVATIONS : activated_by
    ACCOUNTS ||--o{ ACTIVATIONS : performs
    ASSETS ||--o{ ASSET_TRANSFERS : transferred
    ACCOUNTS ||--o{ ASSET_TRANSFERS : from_account
    ACCOUNTS ||--o{ SUPPORT_TICKETS : opens
    ASSETS ||--o{ SUPPORT_TICKETS : optional_asset
    ACCOUNTS ||--o{ ABUSE_REPORTS : reported_account
    ASSETS ||--o{ ABUSE_REPORTS : reported_asset

    COUNTRIES {
        string country_code PK
        string country_name
        int risk_tier
        bool is_restricted
    }

    ACCOUNTS {
        string account_id PK
        string signup_country_code FK
        string payment_fingerprint
        string device_fingerprint
        string shipping_address_fingerprint
        string reseller_id FK
        string synthetic_segment
    }

    ORDERS {
        string order_id PK
        string account_id FK
        timestamp order_ts
        string shipping_country_code FK
        string shipping_node_id FK
        int asset_count
        numeric order_value_usd
    }

    ASSETS {
        string asset_id PK
        string first_order_id FK
        string current_account_id FK
        string current_status
        string synthetic_scenario
    }

    ACTIVATIONS {
        string activation_id PK
        string asset_id FK
        string account_id FK
        timestamp activation_ts
        string activation_country_code FK
    }

    ASSET_TRANSFERS {
        string transfer_id PK
        string asset_id FK
        string from_account_id FK
        string to_account_id FK
        timestamp transfer_ts
        string transfer_reason
    }

    WATCHLIST_ENTITIES {
        string watchlist_id PK
        string entity_type
        string entity_value
        int risk_tier
        string reason_code
    }
```

## Read Path

The core investigation path starts with `accounts`, `orders`, and `assets`, then joins to `activations`, `asset_transfers`, `abuse_reports`, and `chargebacks`. `watchlist_entities` is intentionally generic and fake; it demonstrates matching logic without using real restricted-party data.

