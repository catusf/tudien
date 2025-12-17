"""Generates summary of available dictionaries"""

import argparse
import glob
import json
import os

import langcodes

# Prefer the stdlib tomllib (Py3.11+) but fall back to tomli if necessary
try:
    import tomllib as toml
except Exception:
    import tomli as toml

DOWNLOAD_TAG = "v4.4"  # Set the GitHub tag version that asscociates with the release


def parse_toml_file(toml_path):
    """Parse the .toml file and return its metadata as a dictionary.

    This maps the common keys found in the repository's .toml files to the
    metadata shape expected by the rest of the script.
    """
    metadata = {
        "Name": "",
        "Description": "",
        "Source": "",
        "Target": "",
        "Owner_Editor": "",
        "URL": "",
        "Num_entries": 0,
        "Version": "",
        "Inflections": "",
    }

    try:
        # tomllib/tomli expect a binary file object for load()
        with open(toml_path, "rb") as fh:
            doc = toml.load(fh)

        for key in metadata.keys():
            if key in doc:
                metadata[key] = doc.get(key, metadata[key])

        # # map known keys from the toml file to the metadata dict
        # metadata["Name"] = doc.get("Name", "")
        # metadata["Description"] = doc.get("Description", "")
        # metadata["Source"] = doc.get("Source", "")
        # metadata["Target"] = doc.get("Target", "")
        # metadata["Num_entries"] = doc.get("Num_entries", "")
        # metadata["Owner_Editor"] = doc.get("Owner_Editor", doc.get("Owner_Editor", ""))
        # metadata["URL"] = doc.get("URL", "")
        # metadata["Version"] = doc.get("Version", "")
    except FileNotFoundError:
        print(f"Error: {toml_path} not found.")
    except Exception as exc:
        print(f"Error parsing TOML file {toml_path}: {exc}")

    return metadata


def count_lines_in_tab(tab_path):
    """Count the number of lines in the corresponding .tab file."""
    try:
        with open(tab_path, "r", encoding="utf-8") as file:
            return sum(1 for _ in file)
    except FileNotFoundError:
        print(f"Error: {tab_path} not found.")
        return 0


SUPPORTED_EXTENSIONS = {
    "dictd.zip": {"dir": "dictd", "name": "DictD"},
    "dsl.dz": {"dir": "lingvo", "name": "Lingvo (DSL)"},
    "epub": {"dir": "epub", "name": "EPUB"},
    "kobo.zip": {"dir": "kobo", "name": "Kobo"},
    "mobi": {"dir": "kindle", "name": "Kindle (.mobi)"},
    "stardict.zip": {"dir": "stardict", "name": "StartDict"},
    "yomitan.zip": {"dir": "yomitan", "name": "Yomitan"},
    "mdx": {"dir": "mdict", "name": "MDict"},
    "pleco.zip": {"dir": "pleco", "name": "Pleco"},
    "slob": {"dir": "slob", "name": "Aard 2"},
    "dic": {"dir": "xdxf", "name": "Pocketbook"},
}

COLUMNS = {
    "Name": "Name",
    "Description": "Description",
    "Source": "Source",
    "Target": "Target",
    "Owner_Editor": "Owner_Editor",
    "Url": "URL",
    "Version": "Version",
    "Num_entries": "Num_entries",
}


def get_downloadable_files(filebase, tag_download, output_dir):
    """Return the downloadable file links based on the filebase name."""
    download_links = {}

    for ext in SUPPORTED_EXTENSIONS:
        # Generate the URL for the downloadable file
        download_url = f"https://github.com/catusf/tudien/releases/download/{tag_download}/{filebase}.{ext}"

        download_path = os.path.join(output_dir, f"{filebase}.{ext}")
        
        # print(f"*** Checking for {download_path}")

        if os.path.exists(os.path.join(output_dir, f"{filebase}.{ext}")):
            download_links[ext] = download_url
        else:
            download_links[ext] = ""

    return download_links


def generate_summary(dict_dir, output_dir):
    """Generate a list of dictionaries containing metadata for each .toml file."""
    print(f"Generating summary data for {dict_dir}")

    print(f"Input directory: {dict_dir}\nOutput directory: {output_dir}")
    
    data = []
    needed_files = []
    num_dict_found = 0

    pleco_data = set()

    for filename in os.listdir(dict_dir):
        if filename.endswith(".txt"):
            filebase = filename[:-4]
            pleco_data.add(filebase)

    for filename in os.listdir(dict_dir):
        if not filename.endswith(".toml"):
            continue
        filebase, _ = os.path.splitext(filename)
        toml_path = os.path.join(dict_dir, filename)
        tab_path = os.path.join(dict_dir, filebase + ".tab")

        # Parse the .toml file
        metadata = parse_toml_file(toml_path)

        # Generate the download URL for the main file
        # main_download_url = f"https://github.com/catusf/tudien/releases/tag/{TAG_DOWNLOAD}/all-kindle.zip"

        # Get the additional downloadable files
        download_urls = get_downloadable_files(filebase, DOWNLOAD_TAG, output_dir)

        for ext in SUPPORTED_EXTENSIONS:
            if "pleco.zip" in ext and not filebase in pleco_data:
                continue

            needed_files.append(os.path.join(output_dir, filebase + "." + ext))

        # Get full language names in Vietnamese
        source_full_name = langcodes.Language.get(metadata["Source"]).display_name("vi")
        # language_names.get(metadata['Source'], f"Unknown ({metadata['Source']})")
        target_full_name = langcodes.Language.get(metadata["Target"]).display_name("vi")
        # language_names.get(metadata['Target'], f"Unknown ({metadata['Target']})")

        # Append the data to the list
        data.append(
            {
                "Number": len(data) + 1,  # Add numbering
                "Name": metadata["Name"],
                "Description": metadata["Description"],
                "Source": f"{source_full_name} ({metadata['Source']})",  # Full language name in Vietnamese
                "Target": f"{target_full_name} ({metadata['Target']})",  # Full language name in Vietnamese
                "Owner_Editor": metadata["Owner_Editor"],
                "Version": metadata["Version"],
                "Num_entries": metadata["Num_entries"],  # count_lines_in_tab(tab_path)
                "Download": download_urls,
            }
        )

        num_dict_found += 1

    # for ext in SUPPORTED_EXTENSIONS:
    #     item = SUPPORTED_EXTENSIONS[ext]
    #     needed_files.append(os.path.join(output_dir, f"all-{item['dir']}.zip"))

    # Save the list of dictionaries as a JSON file
    json_path = os.path.join(dict_dir, "dict_summary.json")
    with open(json_path, "w", encoding="utf-8") as json_file:
        json.dump(data, json_file, ensure_ascii=False, indent=4)

        print(f"Data file writtend to '{json_path}'.")

    existing_files = sorted(glob.glob(os.path.join(output_dir, "*.*")))

    missing_files = sorted(set(needed_files) - set(existing_files))

    print("JSON file 'dict_summary.json' has been generated.")

    files_status = "# Status report\n\n"
    files_status += "## Counts\n\n"
    files_per_format = len(SUPPORTED_EXTENSIONS)
    existing_dicts = (len(existing_files) - files_per_format) / files_per_format
    missing_dicts = len(missing_files) / files_per_format

    if existing_dicts < 0:
        existing_dicts = 0
        missing_dicts -= 1

    mismatched_dicts = num_dict_found - (existing_dicts + missing_dicts)

    assert num_dict_found == len(data)
    # assert files_per_format * (num_dict_found + 1) == len(needed_files)

    files_status += f"- There are **{len(data)}** dict files.\n\n"
    files_status += f"- Total NEEDED files: **{len(needed_files)}**\n\n"
    files_status += f"- Total GENERATED files: **{len(existing_files)}** "
    files_status += f"- or **{existing_dicts:.1f}** dictionary sets. "

    normal = False
    if len(missing_files) or len(existing_files) % files_per_format != 0:
        files_status += "ABNORMAL NUMBER of files. Some dict has **missing format(s)**. Check missing files list for details.\n\n"
    else:
        files_status += "The number of files looks NORMAL.\n\n"
        normal = True

    files_status += f"- Total MISSING files: {len(missing_files)}** "
    files_status += f"(or **{missing_dicts:.1f}** dictionaries which is {'CORRECT' if not missing_dicts and mismatched_dicts == 0 else 'IN-CORRECT'})\n\n"

    files_status_details = ""

    if not normal:
        files_status_details += "# Errors\n"

        files_status_details += f"## Missing files list\n\n"
        for item in missing_files:
            files_status_details += f"\t{item}\n"

    print(files_status_details)
    print(files_status)

    return data, files_status, files_status_details


def generate_markdown_table(data, files_status, files_status_details, extensions, columns):
    """Generate a markdown table from the data."""
    print(f"Generating report for {len(data)} dictionaries for {extensions}")

    # Sort the data by "Source" then by "Name"
    data = sorted(data, key=lambda x: (x["Source"], x["Name"]))

    types = [SUPPORTED_EXTENSIONS[ext]["name"] for ext in extensions]
    header = "| Number | Name | "  # " Description | Source | Target | Owner/Editor | Num_entries | " + " | ".join(types)]
    seperator = "| --- | --- | "  # " --- | --- | --- | --- | --- |" + " --- |" * len(extensions)]

    if "Description" in columns:
        header += "Description |"
        seperator += " --- |"

    if "Source" in columns:
        header += "Source |"
        seperator += " --- |"

    if "Target" in columns:
        header += "Target |"
        seperator += " --- |"

    if "Owner_Editor" in columns:
        header += "Owner_Editor |"
        seperator += " --- |"

    if "Version" in columns:
        header += "Version |"
        seperator += " --- |"

    if "Num_entries" in columns:
        header += "# Num_entries |"
        seperator += " ---: |"  # Right align number of definitions

    header += " | ".join(types) + " |"
    seperator += " --- |" * len(extensions)

    header += " Number |"
    seperator += " --- |"

    markdown = [header, seperator]

    for num, entry in enumerate(data, start=1):
        download_links = " | ".join([f"[{ext}]({entry['Download'][ext]})" if entry['Download'][ext] else "N/A" for ext in extensions])

        line = f"| {num} | {entry['Name']} | "

        if "Description" in columns:
            line += f"{entry['Description']} |"

        if "Source" in columns:
            line += f"{entry['Source']} |"

        if "Target" in columns:
            line += f"{entry['Target']} |"

        if "Owner_Editor" in columns:
            line += f"{entry['Owner_Editor']} |"

        if "Version" in columns:
            line += f"{entry['Version']} |"

        if "Num_entries" in columns:
            n = entry['Num_entries']
            line += f"{n:,} |"

        line += f" {download_links} |"

        line += f" {num} |"

        markdown.append(line)

    markdown.insert(0, files_status_details)
    markdown.insert(0, files_status)

    return "\n".join(markdown)


def main():
    """Main function to parse arguments and run the processes."""  # noqa: D202, D401

    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Generate a dictionary summary.")
    parser.add_argument("-d", "--dict_dir", default="dict", help="The directory containing the dictionary files (default is 'dict').")
    parser.add_argument("-f", "--outfile", default="dict_summary.md", help="The output report file name (default is 'dict_summary.md').")
    parser.add_argument("-o", "--output_dir", default="output", help="The output dir for all the dict results.")
    parser.add_argument("-e", "--extensions", default=None, help="The extensions that need included in the report. None means all.")
    parser.add_argument("-c", "--columns", default=None, help="The columns that will be kept (Other than the download links).")
    parser.add_argument("-r", "--read_only", choices=["yes", "no"], default="no", required=False, help="Read data or create it.")

    args = parser.parse_args()

    print(args)

    # Generate the summary data and save it as a JSON file
    ext_str = args.extensions
    col_str = args.columns
    read_only = args.read_only
    dict_dir = args.dict_dir
    outfile = args.outfile
    output_dir = args.output_dir

    extensions = list(SUPPORTED_EXTENSIONS.keys()) if not ext_str else [item.strip() for item in ext_str.split(",")]
    columns = list(COLUMNS.keys()) if not col_str else [item.strip() for item in col_str.split(",")]

    files_status = ""
    files_status_details = ""
    if read_only == "no":
        data, files_status, files_status_details = generate_summary(dict_dir, output_dir)
    else:
        json_path = os.path.join(dict_dir, "dict_summary.json")
        with open(json_path, "r", encoding="utf-8") as json_file:
            data = json.load(json_file)

    # Generate the markdown table from the JSON data
    markdown_table = generate_markdown_table(data, files_status, files_status_details, extensions, columns)

    # Save the markdown table to a .md file
    markdown_file = os.path.join(dict_dir, outfile)
    with open(markdown_file, "w", encoding="utf-8") as file:
        file.write(markdown_table)
        print(f"Data file written to: {markdown_file}")

    print(f"Summary markdown file '{outfile}' has been generated.")


if __name__ == "__main__":
    main()
