DB ?= sql_risk_lab
PSQL ?= psql
PYTHON ?= python3

.PHONY: data validate reset load rebuild run-query olist-download olist-run clean distclean

data:
	$(PYTHON) scripts/generate_synthetic_data.py --out-dir data/generated --seed 42

validate:
	$(PYTHON) scripts/validate_generated_data.py --data-dir data/generated

reset:
	$(PSQL) -d $(DB) -f sql/00_schema.sql

load:
	$(PSQL) -d $(DB) -f sql/10_load_csv.psql
	$(PSQL) -d $(DB) -f sql/20_views.sql
	$(PSQL) -d $(DB) -f sql/30_review_queue.sql

rebuild: data validate reset load

run-query:
	@test -n "$(QUERY)" || (echo "Usage: make run-query QUERY=sql/queries/01_profile_dataset.sql" && exit 1)
	$(PSQL) -d $(DB) -f $(QUERY)

olist-download:
	$(PYTHON) case_studies/olist_marketplace_integrity/scripts/download_olist_data.py

olist-run:
	$(PYTHON) case_studies/olist_marketplace_integrity/scripts/run_olist_case_study.py --rebuild

# Remove untracked local artifacts only; the synthetic CSVs under
# data/generated/ are git-tracked and stay in place.
clean:
	rm -f case_studies/olist_marketplace_integrity/data/olist_marketplace.sqlite

# Also remove regenerable data: the tracked synthetic CSVs (rebuild with
# `make data`) and downloaded Olist raw CSVs (`make olist-download`).
distclean: clean
	rm -f data/generated/*.csv
	rm -f case_studies/olist_marketplace_integrity/data/raw/*.csv
