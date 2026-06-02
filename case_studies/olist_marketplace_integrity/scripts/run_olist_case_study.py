#!/usr/bin/env python3
"""Load Olist CSVs into SQLite and export SQL case-study outputs."""

from __future__ import annotations

import argparse
import csv
import sqlite3
import sys
from pathlib import Path
from typing import Iterable


TABLES = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.csv": "orders",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "product_category_translation",
}

QUERY_FILES = [
    "01_dataset_profile.sql",
    "02_order_integrity_queue.sql",
    "03_seller_integrity_rollup.sql",
    "04_late_delivery_by_route.sql",
    "05_low_review_patterns.sql",
    "06_payment_pattern_review.sql",
    "07_category_fulfillment_risk.sql",
    "08_case_study_metrics.sql",
]


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    case_dir = script_dir.parent
    parser = argparse.ArgumentParser(description="Run Olist marketplace integrity SQL case study.")
    parser.add_argument("--raw-dir", default=str(case_dir / "data" / "raw"))
    parser.add_argument("--db-path", default=str(case_dir / "data" / "olist_marketplace.sqlite"))
    parser.add_argument("--results-dir", default=str(case_dir / "results"))
    parser.add_argument("--rebuild", action="store_true", help="Rebuild the SQLite database before exporting outputs.")
    return parser.parse_args()


def quote_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def clean_value(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    return value if value else None


def require_raw_files(raw_dir: Path) -> list[Path]:
    missing = [filename for filename in TABLES if not (raw_dir / filename).exists()]
    if missing:
        print("Missing Olist raw CSV files:", file=sys.stderr)
        for filename in missing:
            print(f"- {raw_dir / filename}", file=sys.stderr)
        print("\nRun scripts/download_olist_data.py or download the files from Kaggle.", file=sys.stderr)
        return []
    return [raw_dir / filename for filename in TABLES]


def create_table_from_csv(conn: sqlite3.Connection, table_name: str, csv_path: Path) -> int:
    with csv_path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError(f"{csv_path} has no header")

        columns = [quote_identifier(column) for column in reader.fieldnames]
        conn.execute(f"DROP TABLE IF EXISTS {quote_identifier(table_name)}")
        conn.execute(
            f"CREATE TABLE {quote_identifier(table_name)} ("
            + ", ".join(f"{column} TEXT" for column in columns)
            + ")"
        )

        placeholders = ", ".join("?" for _ in reader.fieldnames)
        insert_sql = (
            f"INSERT INTO {quote_identifier(table_name)} ("
            + ", ".join(columns)
            + f") VALUES ({placeholders})"
        )
        row_count = 0
        batch = []
        for row in reader:
            batch.append(tuple(clean_value(row.get(column)) for column in reader.fieldnames))
            row_count += 1
            if len(batch) >= 5000:
                conn.executemany(insert_sql, batch)
                batch.clear()
        if batch:
            conn.executemany(insert_sql, batch)
    return row_count


def create_indexes(conn: sqlite3.Connection) -> None:
    index_sql = [
        "CREATE INDEX IF NOT EXISTS idx_customers_customer_id ON customers(customer_id)",
        "CREATE INDEX IF NOT EXISTS idx_orders_order_id ON orders(order_id)",
        "CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id)",
        "CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)",
        "CREATE INDEX IF NOT EXISTS idx_order_items_seller_id ON order_items(seller_id)",
        "CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id)",
        "CREATE INDEX IF NOT EXISTS idx_order_payments_order_id ON order_payments(order_id)",
        "CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id ON order_reviews(order_id)",
        "CREATE INDEX IF NOT EXISTS idx_products_product_id ON products(product_id)",
        "CREATE INDEX IF NOT EXISTS idx_sellers_seller_id ON sellers(seller_id)",
    ]
    for statement in index_sql:
        conn.execute(statement)


def build_database(conn: sqlite3.Connection, raw_dir: Path, views_sql_path: Path) -> None:
    files = require_raw_files(raw_dir)
    if not files:
        raise FileNotFoundError("Required Olist raw files are missing.")

    print("Loading Olist CSV files into SQLite")
    with conn:
        for csv_path in files:
            table_name = TABLES[csv_path.name]
            row_count = create_table_from_csv(conn, table_name, csv_path)
            print(f"- {table_name}: {row_count}")
        create_indexes(conn)
        conn.executescript(views_sql_path.read_text(encoding="utf-8"))


def fetch_rows(conn: sqlite3.Connection, sql: str) -> tuple[list[str], list[sqlite3.Row]]:
    cursor = conn.execute(sql)
    columns = [description[0] for description in cursor.description]
    rows = cursor.fetchall()
    return columns, rows


def write_csv(path: Path, columns: list[str], rows: Iterable[sqlite3.Row]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(columns)
        for row in rows:
            writer.writerow([row[column] for column in columns])


def markdown_table(columns: list[str], rows: list[sqlite3.Row], limit: int = 10) -> str:
    selected = rows[:limit]
    if not selected:
        return "_No rows returned._\n"

    def cell(value: object) -> str:
        text = "" if value is None else str(value)
        text = text.replace("|", "\\|").replace("\n", " ")
        return text[:140] + "..." if len(text) > 140 else text

    lines = [
        "| " + " | ".join(columns) + " |",
        "| " + " | ".join("---" for _ in columns) + " |",
    ]
    for row in selected:
        lines.append("| " + " | ".join(cell(row[column]) for column in columns) + " |")
    return "\n".join(lines) + "\n"


def export_queries(conn: sqlite3.Connection, case_dir: Path, results_dir: Path) -> dict[str, tuple[list[str], list[sqlite3.Row]]]:
    results_dir.mkdir(parents=True, exist_ok=True)
    query_dir = case_dir / "sql" / "queries"
    outputs: dict[str, tuple[list[str], list[sqlite3.Row]]] = {}

    for filename in QUERY_FILES:
        sql = (query_dir / filename).read_text(encoding="utf-8")
        columns, rows = fetch_rows(conn, sql)
        output_name = filename.replace(".sql", ".csv")
        write_csv(results_dir / output_name, columns, rows)
        outputs[filename] = (columns, rows)
        print(f"Wrote {output_name}: {len(rows)} rows")

    return outputs


def write_summary(results_dir: Path, outputs: dict[str, tuple[list[str], list[sqlite3.Row]]]) -> None:
    profile_columns, profile_rows = outputs["01_dataset_profile.sql"]
    queue_columns, queue_rows = outputs["02_order_integrity_queue.sql"]
    seller_columns, seller_rows = outputs["03_seller_integrity_rollup.sql"]
    route_columns, route_rows = outputs["04_late_delivery_by_route.sql"]
    review_columns, review_rows = outputs["05_low_review_patterns.sql"]
    metrics_columns, metrics_rows = outputs["08_case_study_metrics.sql"]

    summary = [
        "# Olist Marketplace Integrity Case Study Results",
        "",
        "Source: Olist Brazilian E-Commerce Public Dataset.",
        "",
        "These outputs use public marketplace data to demonstrate SQL-based review prioritization. The dataset does not provide confirmed fraud or abuse labels, so scores should be read as operational review signals only.",
        "",
        "## Dataset Profile",
        "",
        markdown_table(profile_columns, profile_rows, limit=20),
        "",
        "## Case Metrics",
        "",
        markdown_table(metrics_columns, metrics_rows, limit=20),
        "",
        "## Top Order Review Queue",
        "",
        markdown_table(queue_columns, queue_rows, limit=10),
        "",
        "## Top Seller Integrity Rollup",
        "",
        markdown_table(seller_columns, seller_rows, limit=10),
        "",
        "## Late Delivery Routes",
        "",
        markdown_table(route_columns, route_rows, limit=10),
        "",
        "## Low Review Patterns",
        "",
        markdown_table(review_columns, review_rows, limit=10),
        "",
        "## Interpretation Notes",
        "",
        "- Late fulfillment, low reviews, high installment counts, and high freight ratios are review signals, not proof of misuse.",
        "- Seller-level scoring is useful for prioritizing operational review, partner-quality checks, and customer-impact analysis.",
        "- The synthetic SQL Risk Lab remains the better place to demonstrate explicit fraud, abuse, diversion, and fake-watchlist scenarios.",
        "",
    ]
    (results_dir / "case_study_summary.md").write_text("\n".join(summary), encoding="utf-8")
    print("Wrote case_study_summary.md")


def main() -> int:
    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    case_dir = script_dir.parent
    raw_dir = Path(args.raw_dir)
    db_path = Path(args.db_path)
    results_dir = Path(args.results_dir)
    views_sql_path = case_dir / "sql" / "00_build_views.sql"

    if args.rebuild and db_path.exists():
        db_path.unlink()

    raw_files = require_raw_files(raw_dir)
    if not raw_files:
        return 1

    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        existing_tables = conn.execute(
            "SELECT COUNT(*) AS table_count FROM sqlite_master WHERE type = 'table'"
        ).fetchone()["table_count"]
        if args.rebuild or existing_tables == 0:
            build_database(conn, raw_dir, views_sql_path)
        else:
            conn.executescript(views_sql_path.read_text(encoding="utf-8"))

        outputs = export_queries(conn, case_dir, results_dir)
        write_summary(results_dir, outputs)
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
