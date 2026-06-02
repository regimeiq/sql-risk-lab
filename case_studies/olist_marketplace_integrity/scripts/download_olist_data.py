#!/usr/bin/env python3
"""Download Olist CSVs from a public Hugging Face mirror.

The canonical source is Kaggle:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

This downloader uses a Hugging Face mirror only because Kaggle downloads usually
require account credentials. Review the dataset terms before publishing raw data.
"""

from __future__ import annotations

import argparse
import ssl
import sys
import urllib.request
from pathlib import Path

try:
    import certifi
except ImportError:  # pragma: no cover - depends on local Python environment
    certifi = None


FILES = [
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
]

BASE_URL = (
    "https://huggingface.co/datasets/"
    "miminmoons/olist-ecommerce-for-delivery-and-review-prediction/"
    "resolve/main/data"
)


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    case_dir = script_dir.parent
    parser = argparse.ArgumentParser(description="Download Olist public CSV files.")
    parser.add_argument(
        "--out-dir",
        default=str(case_dir / "data" / "raw"),
        help="Directory for raw Olist CSV files.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing files.",
    )
    return parser.parse_args()


def download_file(url: str, destination: Path) -> None:
    context = (
        ssl.create_default_context(cafile=certifi.where())
        if certifi
        else ssl.create_default_context()
    )
    with urllib.request.urlopen(url, timeout=120, context=context) as response:
        total = response.headers.get("content-length")
        total_bytes = int(total) if total and total.isdigit() else None
        downloaded = 0
        with destination.open("wb") as handle:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                handle.write(chunk)
                downloaded += len(chunk)
                if total_bytes:
                    pct = 100 * downloaded / total_bytes
                    print(f"  {downloaded / 1_000_000:.1f} MB / {total_bytes / 1_000_000:.1f} MB ({pct:.0f}%)", end="\r")
        print()


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    for filename in FILES:
        destination = out_dir / filename
        if destination.exists() and not args.overwrite:
            print(f"Skipping existing {destination.name}")
            continue

        url = f"{BASE_URL}/{filename}?download=true"
        print(f"Downloading {filename}")
        try:
            download_file(url, destination)
        except Exception as exc:
            if destination.exists():
                destination.unlink()
            print(f"Failed to download {filename}: {exc}", file=sys.stderr)
            return 1

    print(f"Downloaded Olist files to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
