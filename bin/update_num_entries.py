import os
import tomllib  # Python 3.11+ for reading TOML
from pathlib import Path

DICT_DIR = Path("./ext-dict")

for toml_path in DICT_DIR.glob("*.toml"):
    tab_path = toml_path.with_suffix(".tab")

    if not tab_path.exists():
        print(f"⚠️ No matching .tab file for {toml_path.name}, skipped")
        continue

    # Count lines in .tab
    with tab_path.open("r", encoding="utf-8") as f:
        line_count = sum(1 for _ in f)

    # Read TOML
    with toml_path.open("rb") as f:
        data = tomllib.load(f)

    print(f"ℹ️ {toml_path.name}: current num_entries = {data.get('Num_entries', 'N/A')}, counted = {line_count}")

    # Update value
    data["Num_entries"] = line_count

    # Write back to TOML (needs tomli-w for writing)
    import tomli_w
    with toml_path.open("wb") as f:
        tomli_w.dump(data, f)

    print(f"✅ Updated {toml_path.name}: num_entries = {line_count}")
