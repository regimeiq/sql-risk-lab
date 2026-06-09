#!/usr/bin/env python3
"""Generate public-safe synthetic CSV data for SQL Risk Lab."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import random
from collections import defaultdict
from pathlib import Path


START = dt.datetime(2025, 1, 1, 8, 0, 0)
END = dt.datetime(2026, 5, 15, 18, 0, 0)
AS_OF_DATE = dt.date(2026, 6, 1)


COUNTRIES = [
    {"country_code": "C01", "country_name": "Northport Union", "region": "Aster", "risk_tier": 1, "is_restricted": False, "notes": "Low-risk synthetic market"},
    {"country_code": "C02", "country_name": "Greenhaven", "region": "Aster", "risk_tier": 1, "is_restricted": False, "notes": "Low-risk synthetic market"},
    {"country_code": "C03", "country_name": "Lydora", "region": "Boreal", "risk_tier": 2, "is_restricted": False, "notes": "Standard synthetic market"},
    {"country_code": "C04", "country_name": "East Ardent", "region": "Boreal", "risk_tier": 2, "is_restricted": False, "notes": "Standard synthetic market"},
    {"country_code": "C05", "country_name": "Vespera", "region": "Calix", "risk_tier": 3, "is_restricted": False, "notes": "Elevated-risk synthetic market"},
    {"country_code": "C06", "country_name": "Caldera Freeport", "region": "Calix", "risk_tier": 3, "is_restricted": False, "notes": "Elevated-risk synthetic transshipment market"},
    {"country_code": "C07", "country_name": "Orison Belt", "region": "Damar", "risk_tier": 4, "is_restricted": False, "notes": "High-risk synthetic geography"},
    {"country_code": "C08", "country_name": "Kestrel Coast", "region": "Damar", "risk_tier": 4, "is_restricted": False, "notes": "High-risk synthetic geography"},
    {"country_code": "C09", "country_name": "Red Mesa Directorate", "region": "Echelon", "risk_tier": 5, "is_restricted": True, "notes": "Fake restricted geography for watchlist testing"},
    {"country_code": "C10", "country_name": "Iron Vale Compact", "region": "Echelon", "risk_tier": 5, "is_restricted": True, "notes": "Fake restricted geography for watchlist testing"},
]

LOW_RISK_COUNTRIES = ["C01", "C02", "C03", "C04"]
MID_RISK_COUNTRIES = ["C03", "C04", "C05", "C06"]
HIGH_RISK_COUNTRIES = ["C07", "C08"]
RESTRICTED_COUNTRIES = ["C09", "C10"]
ALL_COUNTRY_CODES = [c["country_code"] for c in COUNTRIES]

SAFE_EMAIL_DOMAINS = [
    "examplemail.test",
    "northmail.test",
    "greenpost.test",
    "lydora-inbox.test",
    "ardentmail.test",
    "vespera-mail.test",
]
WATCH_EMAIL_DOMAINS = ["relaydrop.test", "shadowmail.test"]
SUPPORT_LANGUAGES = ["English", "Spanish", "French", "Arabic", "Mandarin", "Portuguese"]
ORDER_CHANNELS = ["web", "partner_portal", "marketplace", "support_assisted", "api"]
ACQUISITION_CHANNELS = ["organic_web", "paid_search", "partner_portal", "marketplace", "support_assisted"]
ASSET_MODELS = ["Atlas-T1", "Atlas-T2", "Beacon-Mini", "Beacon-Pro", "Courier-X"]


CLUSTER_SPECS = [
    {"segment": "shared_payment_alpha", "size": 8, "shared": ["payment", "phone"], "signup_pool": LOW_RISK_COUNTRIES},
    {"segment": "shared_device_beta", "size": 7, "shared": ["device"], "signup_pool": LOW_RISK_COUNTRIES + MID_RISK_COUNTRIES},
    {"segment": "shared_shipping_gamma", "size": 7, "shared": ["shipping"], "signup_pool": LOW_RISK_COUNTRIES},
    {"segment": "bulk_order_burst", "size": 6, "shared": ["payment"], "signup_pool": LOW_RISK_COUNTRIES},
    {"segment": "rapid_transfer_cluster", "size": 7, "shared": ["device"], "signup_pool": LOW_RISK_COUNTRIES + MID_RISK_COUNTRIES},
    {"segment": "diversion_path_cluster", "size": 8, "shared": ["shipping"], "signup_pool": LOW_RISK_COUNTRIES},
    {"segment": "chargeback_cluster", "size": 8, "shared": ["payment"], "signup_pool": LOW_RISK_COUNTRIES + MID_RISK_COUNTRIES},
    {"segment": "abuse_report_cluster", "size": 8, "shared": ["phone", "device"], "signup_pool": MID_RISK_COUNTRIES + HIGH_RISK_COUNTRIES},
    {"segment": "watchlisted_reseller_cluster", "size": 8, "shared": ["reseller", "email_domain"], "signup_pool": LOW_RISK_COUNTRIES + MID_RISK_COUNTRIES},
    {"segment": "support_script_cluster", "size": 8, "shared": ["support_language"], "signup_pool": LOW_RISK_COUNTRIES + MID_RISK_COUNTRIES},
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate synthetic CSV data for SQL Risk Lab.")
    parser.add_argument("--out-dir", default="data/generated", help="Directory for generated CSV files.")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for reproducible output.")
    parser.add_argument("--accounts", type=int, default=360, help="Number of synthetic accounts to generate.")
    return parser.parse_args()


def fingerprint(prefix: str, value: object) -> str:
    digest = hashlib.sha1(str(value).encode("utf-8")).hexdigest()[:12]
    return f"{prefix}_{digest}"


def fmt_ts(value: dt.datetime) -> str:
    return value.strftime("%Y-%m-%d %H:%M:%S")


def fmt_date(value: dt.date) -> str:
    return value.isoformat()


def random_ts(rng: random.Random, start: dt.datetime, end: dt.datetime) -> dt.datetime:
    seconds = int((end - start).total_seconds())
    return start + dt.timedelta(seconds=rng.randint(0, seconds))


def cap_event_ts(value: dt.datetime) -> dt.datetime:
    return min(value, END)


def weighted_choice(rng: random.Random, choices: list[tuple[str, int]]) -> str:
    values = [choice[0] for choice in choices]
    weights = [choice[1] for choice in choices]
    return rng.choices(values, weights=weights, k=1)[0]


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def build_shipping_nodes() -> list[dict]:
    rows = []
    counter = 1
    for country in COUNTRIES:
        for node_type in ("fulfillment_center", "marketplace_node"):
            rows.append(
                {
                    "shipping_node_id": f"SN-{counter:03d}",
                    "node_name": f"{country['country_name']} {node_type.replace('_', ' ').title()}",
                    "node_country_code": country["country_code"],
                    "node_type": node_type,
                    "active": True,
                }
            )
            counter += 1
    return rows


def build_resellers(rng: random.Random) -> list[dict]:
    rows = []
    for i in range(1, 25):
        reseller_id = f"RSL-{i:03d}"
        is_watch = reseller_id in {"RSL-004", "RSL-011"}
        country_pool = MID_RISK_COUNTRIES + HIGH_RISK_COUNTRIES if is_watch else ALL_COUNTRY_CODES[:-2]
        rows.append(
            {
                "reseller_id": reseller_id,
                "reseller_name": f"Synthetic Reseller {i:03d}",
                "registered_country_code": rng.choice(country_pool),
                "reseller_tier": "watch_review" if is_watch else weighted_choice(
                    rng,
                    [("standard", 55), ("preferred", 25), ("marketplace", 20)],
                ),
                "status": "review" if is_watch else weighted_choice(
                    rng,
                    [("active", 85), ("paused", 10), ("terminated", 2), ("review", 3)],
                ),
                "created_at": fmt_ts(random_ts(rng, START - dt.timedelta(days=300), START)),
            }
        )
    return rows


def cluster_values() -> dict[str, dict[str, str]]:
    values: dict[str, dict[str, str]] = {}
    for spec in CLUSTER_SPECS:
        segment = spec["segment"]
        values[segment] = {
            "payment": fingerprint("pay", f"{segment}:payment"),
            "phone": fingerprint("phn", f"{segment}:phone"),
            "device": fingerprint("dev", f"{segment}:device"),
            "shipping": fingerprint("addr", f"{segment}:shipping"),
            "support_language": "Arabic" if segment == "support_script_cluster" else "English",
            "email_domain": WATCH_EMAIL_DOMAINS[0] if segment == "watchlisted_reseller_cluster" else rng_safe_domain(segment),
            "reseller": "RSL-004" if segment == "watchlisted_reseller_cluster" else "",
        }
    return values


def rng_safe_domain(seed_value: str) -> str:
    index = int(hashlib.sha1(seed_value.encode("utf-8")).hexdigest()[:2], 16) % len(SAFE_EMAIL_DOMAINS)
    return SAFE_EMAIL_DOMAINS[index]


def create_account(
    rng: random.Random,
    account_num: int,
    segment: str,
    shared_values: dict[str, str] | None,
    signup_pool: list[str],
) -> dict:
    account_id = f"ACCT-{account_num:06d}"
    created_at = random_ts(rng, START, dt.datetime(2026, 3, 15, 23, 0, 0))
    account_type = weighted_choice(rng, [("individual", 62), ("business", 28), ("reseller", 10)])
    reseller_id = ""
    if account_type in {"business", "reseller"} and rng.random() < 0.35:
        reseller_id = f"RSL-{rng.randint(1, 24):03d}"

    email_domain = rng.choice(SAFE_EMAIL_DOMAINS)
    support_language = weighted_choice(
        rng,
        [("English", 45), ("Spanish", 18), ("French", 12), ("Arabic", 10), ("Mandarin", 8), ("Portuguese", 7)],
    )

    if shared_values:
        if "email_domain" in CLUSTER_SHARED[segment]:
            email_domain = shared_values["email_domain"]
        if "support_language" in CLUSTER_SHARED[segment]:
            support_language = shared_values["support_language"]
        if "reseller" in CLUSTER_SHARED[segment]:
            account_type = "reseller"
            reseller_id = shared_values["reseller"]

    status = weighted_choice(rng, [("active", 86), ("limited", 6), ("closed", 3), ("under_review", 5)])
    if segment in {"diversion_path_cluster", "watchlisted_reseller_cluster", "abuse_report_cluster"}:
        status = weighted_choice(rng, [("active", 55), ("limited", 15), ("under_review", 30)])

    return {
        "account_id": account_id,
        "created_at": fmt_ts(created_at),
        "created_at_dt": created_at,
        "account_type": account_type,
        "signup_country_code": rng.choice(signup_pool),
        "email_fingerprint": fingerprint("eml", account_id),
        "email_domain": email_domain,
        "phone_fingerprint": shared_values["phone"] if shared_values and "phone" in CLUSTER_SHARED[segment] else fingerprint("phn", account_id),
        "payment_fingerprint": shared_values["payment"] if shared_values and "payment" in CLUSTER_SHARED[segment] else fingerprint("pay", account_id),
        "device_fingerprint": shared_values["device"] if shared_values and "device" in CLUSTER_SHARED[segment] else fingerprint("dev", account_id),
        "shipping_address_fingerprint": shared_values["shipping"] if shared_values and "shipping" in CLUSTER_SHARED[segment] else fingerprint("addr", account_id),
        "support_language": support_language,
        "reseller_id": reseller_id,
        "acquisition_channel": weighted_choice(rng, [(c, 1) for c in ACQUISITION_CHANNELS]),
        "status": status,
        "synthetic_segment": segment,
    }


CLUSTER_SHARED = {spec["segment"]: set(spec["shared"]) for spec in CLUSTER_SPECS}


def generate_accounts(rng: random.Random, account_count: int, shared_by_segment: dict[str, dict[str, str]]) -> list[dict]:
    minimum_accounts = sum(spec["size"] for spec in CLUSTER_SPECS)
    if account_count < minimum_accounts:
        raise ValueError(f"--accounts must be at least {minimum_accounts}")

    rows = []
    account_num = 1
    for spec in CLUSTER_SPECS:
        for _ in range(spec["size"]):
            rows.append(
                create_account(
                    rng,
                    account_num,
                    spec["segment"],
                    shared_by_segment[spec["segment"]],
                    spec["signup_pool"],
                )
            )
            account_num += 1

    while len(rows) < account_count:
        rows.append(create_account(rng, account_num, "baseline", None, ALL_COUNTRY_CODES[:-2]))
        account_num += 1

    rng.shuffle(rows)
    return rows


def choose_shipping_country(rng: random.Random, account: dict) -> str:
    segment = account["synthetic_segment"]
    if segment == "diversion_path_cluster":
        return rng.choice(["C01", "C02"])
    if segment == "watchlisted_reseller_cluster":
        return rng.choice(LOW_RISK_COUNTRIES + MID_RISK_COUNTRIES)
    if rng.random() < 0.72:
        return account["signup_country_code"]
    return rng.choice(ALL_COUNTRY_CODES[:-2])


def node_for_country(rng: random.Random, nodes_by_country: dict[str, list[dict]], country_code: str) -> str:
    return rng.choice(nodes_by_country[country_code])["shipping_node_id"]


def order_count_for_account(rng: random.Random, segment: str) -> int:
    if segment == "bulk_order_burst":
        return rng.randint(4, 7)
    if segment in {"diversion_path_cluster", "chargeback_cluster", "watchlisted_reseller_cluster"}:
        return rng.randint(1, 3)
    if segment in {"rapid_transfer_cluster", "abuse_report_cluster", "support_script_cluster"}:
        return rng.randint(1, 2)
    return weighted_choice(rng, [(0, 12), (1, 50), (2, 25), (3, 9), (4, 4)])


def generate_orders_and_assets(
    rng: random.Random,
    accounts: list[dict],
    shipping_nodes: list[dict],
) -> tuple[list[dict], list[dict], list[dict], list[dict], list[dict]]:
    nodes_by_country: dict[str, list[dict]] = defaultdict(list)
    for node in shipping_nodes:
        nodes_by_country[node["node_country_code"]].append(node)

    accounts_by_id = {a["account_id"]: a for a in accounts}
    account_ids = list(accounts_by_id)
    orders = []
    assets = []
    order_items = []
    activations = []
    transfers = []

    order_num = 1
    asset_num = 1
    item_num = 1
    activation_num = 1
    transfer_num = 1

    for account in accounts:
        segment = account["synthetic_segment"]
        count = order_count_for_account(rng, segment)
        if count == 0:
            continue

        created_at = account["created_at_dt"]
        if segment == "bulk_order_burst":
            burst_start = random_ts(rng, max(created_at + dt.timedelta(days=1), START), END - dt.timedelta(days=20))
            order_times = [burst_start + dt.timedelta(hours=rng.randint(0, 18), minutes=rng.randint(0, 59)) for _ in range(count)]
            order_times.sort()
        else:
            order_times = [
                random_ts(rng, max(created_at + dt.timedelta(days=1), START), END - dt.timedelta(days=10))
                for _ in range(count)
            ]
            order_times.sort()

        for order_ts in order_times:
            order_id = f"ORD-{order_num:07d}"
            order_num += 1
            shipping_country = choose_shipping_country(rng, account)
            asset_count = rng.randint(2, 5) if segment == "bulk_order_burst" else weighted_choice(rng, [(1, 72), (2, 20), (3, 6), (4, 2)])
            unit_price = rng.choice([199, 249, 299, 399, 499, 699])
            order_value = asset_count * unit_price
            order_channel = "partner_portal" if account["account_type"] == "reseller" else rng.choice(ORDER_CHANNELS)
            if segment == "watchlisted_reseller_cluster":
                order_channel = "partner_portal"

            orders.append(
                {
                    "order_id": order_id,
                    "account_id": account["account_id"],
                    "order_ts": fmt_ts(order_ts),
                    "order_ts_dt": order_ts,
                    "order_channel": order_channel,
                    "shipping_country_code": shipping_country,
                    "shipping_node_id": node_for_country(rng, nodes_by_country, shipping_country),
                    "shipping_address_fingerprint": account["shipping_address_fingerprint"],
                    "payment_fingerprint": account["payment_fingerprint"],
                    "device_fingerprint": account["device_fingerprint"],
                    "order_value_usd": f"{order_value:.2f}",
                    "asset_count": asset_count,
                    "order_status": weighted_choice(rng, [("paid", 14), ("fulfilled", 82), ("cancelled", 2), ("refunded", 2)]),
                    "synthetic_scenario": segment,
                }
            )

            for _ in range(asset_count):
                asset_id = f"ASSET-{asset_num:07d}"
                serial = f"AST-{AS_OF_DATE.year}-{asset_num:08d}"
                asset_num += 1
                manufactured_at = (order_ts - dt.timedelta(days=rng.randint(30, 420))).date()
                asset = {
                    "asset_id": asset_id,
                    "serial_number": serial,
                    "model": rng.choice(ASSET_MODELS),
                    "manufactured_at": fmt_date(manufactured_at),
                    "first_order_id": order_id,
                    "current_account_id": account["account_id"],
                    "current_status": "shipped",
                    "synthetic_scenario": segment,
                }
                assets.append(asset)
                order_items.append(
                    {
                        "order_item_id": f"ITEM-{item_num:08d}",
                        "order_id": order_id,
                        "asset_id": asset_id,
                        "unit_price_usd": f"{unit_price:.2f}",
                    }
                )
                item_num += 1

                should_transfer = (
                    segment in {"rapid_transfer_cluster", "diversion_path_cluster"}
                    or (segment == "watchlisted_reseller_cluster" and rng.random() < 0.38)
                    or rng.random() < 0.025
                )
                activation_account_id = account["account_id"]
                activation_start = cap_event_ts(order_ts + dt.timedelta(days=rng.randint(1, 35)))
                if should_transfer:
                    to_account_id = rng.choice([aid for aid in account_ids if aid != account["account_id"]])
                    to_account = accounts_by_id[to_account_id]
                    transfer_delay_days = rng.randint(2, 12) if segment in {"rapid_transfer_cluster", "diversion_path_cluster"} else rng.randint(15, 120)
                    transfer_ts = cap_event_ts(order_ts + dt.timedelta(days=transfer_delay_days, hours=rng.randint(0, 23)))
                    transfer_country = rng.choice(RESTRICTED_COUNTRIES + HIGH_RISK_COUNTRIES) if segment == "diversion_path_cluster" else to_account["signup_country_code"]
                    transfers.append(
                        {
                            "transfer_id": f"XFER-{transfer_num:08d}",
                            "asset_id": asset_id,
                            "from_account_id": account["account_id"],
                            "to_account_id": to_account_id,
                            "transfer_ts": fmt_ts(transfer_ts),
                            "transfer_ts_dt": transfer_ts,
                            "transfer_reason": weighted_choice(
                                rng,
                                [("resale", 45), ("marketplace_transfer", 25), ("business_reassignment", 15), ("support_replacement", 10), ("unknown", 5)],
                            ),
                            "initiated_by": weighted_choice(
                                rng,
                                [("account_holder", 55), ("reseller_portal", 25), ("support_agent", 15), ("system", 5)],
                            ),
                            "transfer_country_code": transfer_country,
                        }
                    )
                    transfer_num += 1
                    asset["current_account_id"] = to_account_id
                    asset["current_status"] = "transferred"
                    activation_account_id = to_account_id
                    activation_start = cap_event_ts(transfer_ts + dt.timedelta(days=rng.randint(1, 20)))

                if rng.random() < 0.9:
                    if segment == "diversion_path_cluster":
                        activation_country = rng.choice(RESTRICTED_COUNTRIES + HIGH_RISK_COUNTRIES)
                    elif segment == "watchlisted_reseller_cluster" and rng.random() < 0.30:
                        activation_country = rng.choice(HIGH_RISK_COUNTRIES + RESTRICTED_COUNTRIES)
                    elif rng.random() < 0.86:
                        activation_country = shipping_country
                    else:
                        activation_country = rng.choice(ALL_COUNTRY_CODES)

                    activations.append(
                        {
                            "activation_id": f"ACT-{activation_num:08d}",
                            "asset_id": asset_id,
                            "account_id": activation_account_id,
                            "activation_ts": fmt_ts(activation_start),
                            "activation_ts_dt": activation_start,
                            "activation_country_code": activation_country,
                            "activation_region": f"{activation_country}-R{rng.randint(1, 6)}",
                            "ip_fingerprint": fingerprint("ip", f"{asset_id}:{activation_start.date()}:{activation_country}"),
                            "device_fingerprint": accounts_by_id[activation_account_id]["device_fingerprint"],
                        }
                    )
                    activation_num += 1
                    if asset["current_status"] == "shipped":
                        asset["current_status"] = "active"

                    if segment in {"abuse_report_cluster", "diversion_path_cluster"} and rng.random() < 0.22:
                        second_activation_ts = cap_event_ts(activation_start + dt.timedelta(days=rng.randint(10, 90)))
                        second_account_id = rng.choice([aid for aid in account_ids if aid != activation_account_id])
                        second_country = rng.choice(HIGH_RISK_COUNTRIES + RESTRICTED_COUNTRIES)
                        activations.append(
                            {
                                "activation_id": f"ACT-{activation_num:08d}",
                                "asset_id": asset_id,
                                "account_id": second_account_id,
                                "activation_ts": fmt_ts(second_activation_ts),
                                "activation_ts_dt": second_activation_ts,
                                "activation_country_code": second_country,
                                "activation_region": f"{second_country}-R{rng.randint(1, 6)}",
                                "ip_fingerprint": fingerprint("ip", f"{asset_id}:{second_activation_ts.date()}:{second_country}"),
                                "device_fingerprint": accounts_by_id[second_account_id]["device_fingerprint"],
                            }
                        )
                        activation_num += 1
                        asset["current_account_id"] = second_account_id
                        asset["current_status"] = "active"

    return orders, assets, order_items, activations, transfers


def generate_chargebacks(rng: random.Random, orders: list[dict], accounts_by_id: dict[str, dict]) -> list[dict]:
    rows = []
    counter = 1
    for order in orders:
        segment = order["synthetic_scenario"]
        probability = 0.025
        if segment == "chargeback_cluster":
            probability = 0.58
        elif segment == "bulk_order_burst":
            probability = 0.24
        elif segment in {"diversion_path_cluster", "watchlisted_reseller_cluster"}:
            probability = 0.18

        if rng.random() >= probability:
            continue

        order_ts = order["order_ts_dt"]
        chargeback_ts = min(order_ts + dt.timedelta(days=rng.randint(12, 95), hours=rng.randint(0, 23)), END)
        amount = float(order["order_value_usd"]) * rng.uniform(0.55, 1.0)
        rows.append(
            {
                "chargeback_id": f"CBK-{counter:08d}",
                "order_id": order["order_id"],
                "account_id": order["account_id"],
                "chargeback_ts": fmt_ts(chargeback_ts),
                "reason_code": weighted_choice(
                    rng,
                    [("fraudulent", 44), ("product_not_received", 24), ("duplicate", 10), ("subscription_dispute", 8), ("unknown", 14)],
                ),
                "amount_usd": f"{amount:.2f}",
                "dispute_status": weighted_choice(rng, [("open", 35), ("won", 20), ("lost", 35), ("withdrawn", 10)]),
            }
        )
        counter += 1
    return rows


def generate_support_tickets(
    rng: random.Random,
    accounts: list[dict],
    assets: list[dict],
    activations: list[dict],
) -> list[dict]:
    assets_by_account: dict[str, list[str]] = defaultdict(list)
    for asset in assets:
        assets_by_account[asset["current_account_id"]].append(asset["asset_id"])
    for activation in activations:
        assets_by_account[activation["account_id"]].append(activation["asset_id"])

    rows = []
    counter = 1
    for account in accounts:
        segment = account["synthetic_segment"]
        if segment == "support_script_cluster":
            ticket_count = rng.randint(3, 5)
        else:
            ticket_count = weighted_choice(rng, [(0, 58), (1, 30), (2, 9), (3, 3)])

        for i in range(ticket_count):
            opened_at = random_ts(rng, account["created_at_dt"] + dt.timedelta(days=1), END)
            asset_id = ""
            if assets_by_account[account["account_id"]] and rng.random() < 0.65:
                asset_id = rng.choice(assets_by_account[account["account_id"]])
            if segment == "support_script_cluster":
                message = fingerprint("msg", "support_script_cluster:activation_transfer_language")
                reason = weighted_choice(rng, [("activation_help", 40), ("transfer_request", 45), ("policy_question", 15)])
            else:
                reason = weighted_choice(
                    rng,
                    [("activation_help", 36), ("billing_dispute", 18), ("transfer_request", 18), ("device_issue", 18), ("policy_question", 10)],
                )
                message = fingerprint("msg", f"{account['account_id']}:{i}:{reason}")
            rows.append(
                {
                    "ticket_id": f"TCK-{counter:08d}",
                    "account_id": account["account_id"],
                    "asset_id": asset_id,
                    "opened_at": fmt_ts(opened_at),
                    "support_language": account["support_language"],
                    "reason_code": reason,
                    "country_code": account["signup_country_code"],
                    "message_fingerprint": message,
                }
            )
            counter += 1
    return rows


def generate_abuse_reports(
    rng: random.Random,
    accounts: list[dict],
    assets: list[dict],
    activations: list[dict],
) -> list[dict]:
    activations_by_asset: dict[str, list[dict]] = defaultdict(list)
    for activation in activations:
        activations_by_asset[activation["asset_id"]].append(activation)

    asset_by_id = {asset["asset_id"]: asset for asset in assets}
    assets_by_segment: dict[str, list[dict]] = defaultdict(list)
    for asset in assets:
        assets_by_segment[asset["synthetic_scenario"]].append(asset)

    rows = []
    counter = 1

    for asset in assets:
        segment = asset["synthetic_scenario"]
        probability = 0.018
        if segment == "abuse_report_cluster":
            probability = 0.48
        elif segment in {"diversion_path_cluster", "watchlisted_reseller_cluster"}:
            probability = 0.22
        elif segment == "rapid_transfer_cluster":
            probability = 0.12

        if rng.random() >= probability:
            continue

        report_count = rng.randint(2, 5) if segment == "abuse_report_cluster" else 1
        base_ts = random_ts(rng, START + dt.timedelta(days=20), END)
        account_id = asset["current_account_id"]
        country = "C05"
        if activations_by_asset[asset["asset_id"]]:
            latest_activation = max(activations_by_asset[asset["asset_id"]], key=lambda item: item["activation_ts_dt"])
            account_id = latest_activation["account_id"]
            country = latest_activation["activation_country_code"]

        for i in range(report_count):
            report_account_id = account_id if rng.random() < 0.85 else ""
            report_asset_id = asset["asset_id"] if rng.random() < 0.9 else ""
            if not report_account_id and not report_asset_id:
                # The abuse_reports CHECK constraint requires account_id or asset_id.
                # Restore the asset link post-hoc so the RNG draw sequence is unchanged.
                report_asset_id = asset["asset_id"]
            rows.append(
                {
                    "report_id": f"RPT-{counter:08d}",
                    "account_id": report_account_id,
                    "asset_id": report_asset_id,
                    "report_ts": fmt_ts(base_ts + dt.timedelta(hours=i * rng.randint(3, 18))),
                    "report_type": weighted_choice(
                        rng,
                        [("misuse_report", 35), ("chargeback_abuse", 20), ("policy_evasion", 20), ("unsafe_resale", 15), ("identity_concern", 10)],
                    ),
                    "reporter_type": weighted_choice(rng, [("customer", 35), ("internal", 25), ("partner", 20), ("automated", 20)]),
                    "country_code": country,
                    "severity": rng.randint(2, 5) if segment != "baseline" else rng.randint(1, 4),
                    "narrative_fingerprint": fingerprint("nar", f"{asset['asset_id']}:{segment}:{i}"),
                }
            )
            counter += 1

    for account in accounts:
        if account["synthetic_segment"] != "abuse_report_cluster":
            continue
        for i in range(rng.randint(1, 3)):
            rows.append(
                {
                    "report_id": f"RPT-{counter:08d}",
                    "account_id": account["account_id"],
                    "asset_id": "",
                    "report_ts": fmt_ts(random_ts(rng, account["created_at_dt"] + dt.timedelta(days=10), END)),
                    "report_type": "policy_evasion",
                    "reporter_type": "internal",
                    "country_code": account["signup_country_code"],
                    "severity": rng.randint(3, 5),
                    "narrative_fingerprint": fingerprint("nar", f"{account['account_id']}:account_level:{i}"),
                }
            )
            counter += 1

    return rows


def generate_watchlist_entities(shared_by_segment: dict[str, dict[str, str]]) -> list[dict]:
    rows = []
    counter = 1

    def add(entity_type: str, entity_value: str, label: str, risk_tier: int, reason: str) -> None:
        nonlocal counter
        rows.append(
            {
                "watchlist_id": f"WLT-{counter:06d}",
                "entity_type": entity_type,
                "entity_value": entity_value,
                "entity_label": label,
                "risk_tier": risk_tier,
                "reason_code": reason,
                "active_from": "2025-01-01",
                "active_to": "",
                "source_note": "Synthetic watchlist entry for public-safe SQL lab",
            }
        )
        counter += 1

    add("country_code", "C09", "Red Mesa Directorate", 5, "fake_restricted_country")
    add("country_code", "C10", "Iron Vale Compact", 5, "fake_restricted_country")
    add("reseller_id", "RSL-004", "Synthetic Reseller 004", 5, "fake_reseller_review")
    add("reseller_id", "RSL-011", "Synthetic Reseller 011", 4, "fake_reseller_review")
    add("email_domain", "relaydrop.test", "Relaydrop Test Domain", 4, "fake_disposable_domain")
    add("email_domain", "shadowmail.test", "Shadowmail Test Domain", 4, "fake_disposable_domain")
    add("payment_fingerprint", shared_by_segment["shared_payment_alpha"]["payment"], "Shared Payment Alpha", 4, "fake_shared_payment_cluster")
    add("device_fingerprint", shared_by_segment["shared_device_beta"]["device"], "Shared Device Beta", 4, "fake_shared_device_cluster")
    add("shipping_address_fingerprint", shared_by_segment["shared_shipping_gamma"]["shipping"], "Shared Shipping Gamma", 4, "fake_shared_shipping_cluster")
    add("phone_fingerprint", shared_by_segment["abuse_report_cluster"]["phone"], "Abuse Cluster Phone", 4, "fake_shared_phone_cluster")
    return rows


def strip_internal_fields(rows: list[dict]) -> list[dict]:
    cleaned = []
    for row in rows:
        cleaned.append({key: value for key, value in row.items() if not key.endswith("_dt")})
    return cleaned


def main() -> None:
    args = parse_args()
    rng = random.Random(args.seed)
    out_dir = Path(args.out_dir)

    shared_by_segment = cluster_values()
    countries = COUNTRIES
    shipping_nodes = build_shipping_nodes()
    resellers = build_resellers(rng)
    watchlist = generate_watchlist_entities(shared_by_segment)
    accounts = generate_accounts(rng, args.accounts, shared_by_segment)
    orders, assets, order_items, activations, transfers = generate_orders_and_assets(rng, accounts, shipping_nodes)
    accounts_by_id = {account["account_id"]: account for account in accounts}
    chargebacks = generate_chargebacks(rng, orders, accounts_by_id)
    support_tickets = generate_support_tickets(rng, accounts, assets, activations)
    abuse_reports = generate_abuse_reports(rng, accounts, assets, activations)

    write_csv(
        out_dir / "countries.csv",
        countries,
        ["country_code", "country_name", "region", "risk_tier", "is_restricted", "notes"],
    )
    write_csv(
        out_dir / "watchlist_entities.csv",
        watchlist,
        ["watchlist_id", "entity_type", "entity_value", "entity_label", "risk_tier", "reason_code", "active_from", "active_to", "source_note"],
    )
    write_csv(
        out_dir / "shipping_nodes.csv",
        shipping_nodes,
        ["shipping_node_id", "node_name", "node_country_code", "node_type", "active"],
    )
    write_csv(
        out_dir / "reseller_profiles.csv",
        resellers,
        ["reseller_id", "reseller_name", "registered_country_code", "reseller_tier", "status", "created_at"],
    )
    write_csv(
        out_dir / "accounts.csv",
        strip_internal_fields(accounts),
        [
            "account_id",
            "created_at",
            "account_type",
            "signup_country_code",
            "email_fingerprint",
            "email_domain",
            "phone_fingerprint",
            "payment_fingerprint",
            "device_fingerprint",
            "shipping_address_fingerprint",
            "support_language",
            "reseller_id",
            "acquisition_channel",
            "status",
            "synthetic_segment",
        ],
    )
    write_csv(
        out_dir / "orders.csv",
        strip_internal_fields(orders),
        [
            "order_id",
            "account_id",
            "order_ts",
            "order_channel",
            "shipping_country_code",
            "shipping_node_id",
            "shipping_address_fingerprint",
            "payment_fingerprint",
            "device_fingerprint",
            "order_value_usd",
            "asset_count",
            "order_status",
            "synthetic_scenario",
        ],
    )
    write_csv(
        out_dir / "assets.csv",
        assets,
        ["asset_id", "serial_number", "model", "manufactured_at", "first_order_id", "current_account_id", "current_status", "synthetic_scenario"],
    )
    write_csv(
        out_dir / "order_items.csv",
        order_items,
        ["order_item_id", "order_id", "asset_id", "unit_price_usd"],
    )
    write_csv(
        out_dir / "activations.csv",
        strip_internal_fields(activations),
        ["activation_id", "asset_id", "account_id", "activation_ts", "activation_country_code", "activation_region", "ip_fingerprint", "device_fingerprint"],
    )
    write_csv(
        out_dir / "asset_transfers.csv",
        strip_internal_fields(transfers),
        ["transfer_id", "asset_id", "from_account_id", "to_account_id", "transfer_ts", "transfer_reason", "initiated_by", "transfer_country_code"],
    )
    write_csv(
        out_dir / "support_tickets.csv",
        support_tickets,
        ["ticket_id", "account_id", "asset_id", "opened_at", "support_language", "reason_code", "country_code", "message_fingerprint"],
    )
    write_csv(
        out_dir / "abuse_reports.csv",
        abuse_reports,
        ["report_id", "account_id", "asset_id", "report_ts", "report_type", "reporter_type", "country_code", "severity", "narrative_fingerprint"],
    )
    write_csv(
        out_dir / "chargebacks.csv",
        chargebacks,
        ["chargeback_id", "order_id", "account_id", "chargeback_ts", "reason_code", "amount_usd", "dispute_status"],
    )

    print(f"Generated SQL Risk Lab data in {out_dir}")
    print(f"Accounts: {len(accounts)}")
    print(f"Orders: {len(orders)}")
    print(f"Assets: {len(assets)}")
    print(f"Activations: {len(activations)}")
    print(f"Transfers: {len(transfers)}")
    print(f"Support tickets: {len(support_tickets)}")
    print(f"Abuse reports: {len(abuse_reports)}")
    print(f"Chargebacks: {len(chargebacks)}")


if __name__ == "__main__":
    main()
