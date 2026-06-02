# Assumptions and Limitations

## Assumptions

- All countries, resellers, entities, accounts, addresses, devices, payments, and watchlist values are synthetic.
- Identifier fields are represented as fingerprints rather than raw PII.
- Country risk tiers are invented and do not map to real jurisdictions.
- Watchlist entries are fake and exist only to demonstrate matching logic.
- Timestamps are generated in UTC-like local timestamps without timezone modeling.
- The review queue is a deterministic SQL triage layer, not a machine-learning model.

## Limitations

- Synthetic data cannot prove operational effectiveness against real abuse.
- Risk weights are illustrative and should be calibrated against real labels in a production environment.
- False positives are expected, especially for shared identifiers and reseller behavior.
- False negatives are expected where actors avoid reuse, delay transfers, or keep activity below thresholds.
- The schema simplifies many production realities, including refunds, partial shipments, device telemetry, identity proofing, sanctions screening vendors, and legal review workflows.
- This project is not legal, compliance, or enforcement advice.

## Public-Safe Boundaries

This lab avoids real restricted-party lists, real sanctions programs, real export-control classifications, real customer records, and real evasion instructions. The diversion scenarios are framed as review patterns using fake geography and fake entities.

