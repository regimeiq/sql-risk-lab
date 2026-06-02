#!/usr/bin/env python3
"""Lightweight CSV integrity checks for SQL Risk Lab generated data."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import sys
from pathlib import Path


AS_OF = dt.datetime(2026, 6, 1, 0, 0, 0)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate generated SQL Risk Lab CSV files.")
    parser.add_argument("--data-dir", default="data/generated", help="Directory containing generated CSV files.")
    return parser.parse_args()


def read_csv(data_dir: Path, name: str) -> list[dict[str, str]]:
    path = data_dir / f"{name}.csv"
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def ids(rows: list[dict[str, str]], key: str) -> set[str]:
    return {row[key] for row in rows if row.get(key)}


def check_subset(failures: list[str], label: str, values: set[str], allowed: set[str]) -> None:
    missing = sorted(value for value in values if value and value not in allowed)
    if missing:
        failures.append(f"{label}: {len(missing)} missing references, first={missing[:5]}")


def check_timestamps(failures: list[str], rows: list[dict[str, str]], table: str, column: str) -> None:
    future_values = []
    for row in rows:
        value = row.get(column)
        if not value:
            continue
        parsed = dt.datetime.fromisoformat(value)
        if parsed >= AS_OF:
            future_values.append(value)
    if future_values:
        failures.append(f"{table}.{column}: {len(future_values)} timestamps on/after {AS_OF.date()}")


def main() -> int:
    args = parse_args()
    data_dir = Path(args.data_dir)

    tables = {
        name: read_csv(data_dir, name)
        for name in [
            "countries",
            "watchlist_entities",
            "shipping_nodes",
            "reseller_profiles",
            "accounts",
            "orders",
            "assets",
            "order_items",
            "activations",
            "asset_transfers",
            "support_tickets",
            "abuse_reports",
            "chargebacks",
        ]
    }

    country_ids = ids(tables["countries"], "country_code")
    node_ids = ids(tables["shipping_nodes"], "shipping_node_id")
    reseller_ids = ids(tables["reseller_profiles"], "reseller_id")
    account_ids = ids(tables["accounts"], "account_id")
    order_ids = ids(tables["orders"], "order_id")
    asset_ids = ids(tables["assets"], "asset_id")

    failures: list[str] = []
    check_subset(failures, "shipping_nodes.node_country_code", ids(tables["shipping_nodes"], "node_country_code"), country_ids)
    check_subset(failures, "reseller_profiles.registered_country_code", ids(tables["reseller_profiles"], "registered_country_code"), country_ids)
    check_subset(failures, "accounts.signup_country_code", ids(tables["accounts"], "signup_country_code"), country_ids)
    check_subset(failures, "accounts.reseller_id", ids(tables["accounts"], "reseller_id"), reseller_ids)
    check_subset(failures, "orders.account_id", ids(tables["orders"], "account_id"), account_ids)
    check_subset(failures, "orders.shipping_country_code", ids(tables["orders"], "shipping_country_code"), country_ids)
    check_subset(failures, "orders.shipping_node_id", ids(tables["orders"], "shipping_node_id"), node_ids)
    check_subset(failures, "assets.first_order_id", ids(tables["assets"], "first_order_id"), order_ids)
    check_subset(failures, "assets.current_account_id", ids(tables["assets"], "current_account_id"), account_ids)
    check_subset(failures, "order_items.order_id", ids(tables["order_items"], "order_id"), order_ids)
    check_subset(failures, "order_items.asset_id", ids(tables["order_items"], "asset_id"), asset_ids)
    check_subset(failures, "activations.asset_id", ids(tables["activations"], "asset_id"), asset_ids)
    check_subset(failures, "activations.account_id", ids(tables["activations"], "account_id"), account_ids)
    check_subset(failures, "activations.activation_country_code", ids(tables["activations"], "activation_country_code"), country_ids)
    check_subset(failures, "asset_transfers.asset_id", ids(tables["asset_transfers"], "asset_id"), asset_ids)
    check_subset(failures, "asset_transfers.from_account_id", ids(tables["asset_transfers"], "from_account_id"), account_ids)
    check_subset(failures, "asset_transfers.to_account_id", ids(tables["asset_transfers"], "to_account_id"), account_ids)
    check_subset(failures, "asset_transfers.transfer_country_code", ids(tables["asset_transfers"], "transfer_country_code"), country_ids)
    check_subset(failures, "support_tickets.account_id", ids(tables["support_tickets"], "account_id"), account_ids)
    check_subset(failures, "support_tickets.asset_id", ids(tables["support_tickets"], "asset_id"), asset_ids)
    check_subset(failures, "support_tickets.country_code", ids(tables["support_tickets"], "country_code"), country_ids)
    check_subset(failures, "abuse_reports.account_id", ids(tables["abuse_reports"], "account_id"), account_ids)
    check_subset(failures, "abuse_reports.asset_id", ids(tables["abuse_reports"], "asset_id"), asset_ids)
    check_subset(failures, "abuse_reports.country_code", ids(tables["abuse_reports"], "country_code"), country_ids)
    check_subset(failures, "chargebacks.order_id", ids(tables["chargebacks"], "order_id"), order_ids)
    check_subset(failures, "chargebacks.account_id", ids(tables["chargebacks"], "account_id"), account_ids)

    for table, column in [
        ("accounts", "created_at"),
        ("orders", "order_ts"),
        ("activations", "activation_ts"),
        ("asset_transfers", "transfer_ts"),
        ("support_tickets", "opened_at"),
        ("abuse_reports", "report_ts"),
        ("chargebacks", "chargeback_ts"),
    ]:
        check_timestamps(failures, tables[table], table, column)

    ordered_assets = [row["asset_id"] for row in tables["order_items"]]
    if len(ordered_assets) != len(set(ordered_assets)):
        failures.append("order_items.asset_id: duplicate asset order lines")

    if failures:
        print("Validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Validation passed.")
    for name in sorted(tables):
        print(f"{name}: {len(tables[name])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

