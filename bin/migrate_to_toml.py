import os
import re

INPUT_FOLDER = "./ext-dict"   # change if needed

def normalize_key(key: str) -> str:
    # Replace illegal TOML key characters with underscore
    # TOML keys must contain only: A-Z a-z 0-9 _ - and no spaces unless quoted
    key = key.strip()
    key = re.sub(r"[^A-Za-z0-9_-]", "_", key)
    return key

for filename in os.listdir(INPUT_FOLDER):
    if filename.endswith(".dfo"):
        dfo_path = os.path.join(INPUT_FOLDER, filename)
        toml_path = os.path.join(INPUT_FOLDER, filename.replace(".dfo", ".toml"))

        data = {}

        with open(dfo_path, "r", encoding="utf-8") as f:
            for line in f:
                if "=" not in line:
                    continue
                key, value = line.split("=", 1)
                key = normalize_key(key)
                value = value.strip()

                # Convert empty values to ""
                if value == "":
                    value = '""'
                else:
                    # Wrap value in quotes
                    value = f'"{value}"'

                data[key] = value

        with open(toml_path, "w", encoding="utf-8") as f:
            for k, v in data.items():
                f.write(f"{k} = {v}\n")

        print(f"Converted: {filename} → {os.path.basename(toml_path)}")
