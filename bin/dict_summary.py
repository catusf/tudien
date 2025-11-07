"""Generates summary of available dictionaries"""

import argparse
import glob
import json
import os

import langcodes

DOWNLOAD_TAG = "v4.2"  # Set the GitHub tag version that asscociates with the release


def parse_dfo_file(dfo_path):
    """Parse the .dfo file and return its metadata as a dictionary."""
    metadata = {
        "Name": "",
        "Description": "",
        "Source": "",
        "Target": "",
        "Owner/Editor": "",
        "URL": "",
        "Version": "",  # Add version
    }

    try:
        with open(dfo_path, "r", encoding="utf-8") as file:
            for line in file:
                if line.startswith("Name = "):
                    metadata["Name"] = line[len("Name = ") :].strip()
                elif line.startswith("Description = "):
                    metadata["Description"] = line[len("Description = ") :].strip()
                elif line.startswith("Source = "):
                    metadata["Source"] = line[len("Source = ") :].strip()
                elif line.startswith("Target = "):
                    metadata["Target"] = line[len("Target = ") :].strip()
                elif line.startswith("Owner/Editor = "):
                    metadata["Owner/Editor"] = line[len("Owner/Editor = ") :].strip()
                elif line.startswith("URL = "):
                    metadata["URL"] = line[len("URL = ") :].strip()
                elif line.startswith("Version = "):
                    metadata["Version"] = line[len("Version = ") :].strip()  # Get the version
    except FileNotFoundError:
        print(f"Error: {dfo_path} not found.")

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
}

COLUMNS = {
    "name": "Name",
    "desc": "Description",
    "source": "Source",
    "target": "Target",
    "owner": "Owner",
    "url": "URL",
    "version": "Version",
    "definition": "Definitions",
}


def get_downloadable_files(filebase, tag_download, dict_dir):
    """Return the downloadable file links based on the filebase name."""
    download_links = {}

    for ext in SUPPORTED_EXTENSIONS:
        # Generate the URL for the downloadable file
        download_url = f"https://github.com/catusf/tudien/releases/download/{tag_download}/{filebase}.{ext}"

        if os.path.exists(os.path.join(dict_dir, f"{filebase}.{ext}")):
            download_links[ext] = download_url
        else:
            download_links[ext] = ""

    return download_links


def generate_summary(dict_dir, output_dir):
    """Generate a list of dictionaries containing metadata for each .dfo file."""
    print(f"Generating summary data for {dict_dir}")

    print(f"Input directory: {dict_dir}\nOutput directory: {output_dir}")
    
    data = []
    needed_files = []
    num_dict_found = 0

    for filename in os.listdir(dict_dir):
        if not filename.endswith(".dfo"):
            continue
        filebase = filename[:-4]
        dfo_path = os.path.join(dict_dir, filename)
        tab_path = os.path.join(dict_dir, filebase + ".tab")

        # Parse the .dfo file
        metadata = parse_dfo_file(dfo_path)

        # Count lines in the corresponding .tab file
        num_definitions = count_lines_in_tab(tab_path)

        # Generate the download URL for the main file
        # main_download_url = f"https://github.com/catusf/tudien/releases/tag/{TAG_DOWNLOAD}/all-kindle.zip"

        # Get the additional downloadable files
        download_urls = get_downloadable_files(filebase, DOWNLOAD_TAG, dict_dir)

        for ext in SUPPORTED_EXTENSIONS:
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
                "Owner/Editor": metadata["Owner/Editor"],
                "Version": metadata["Version"],
                "Definitions": num_definitions,
                "Download": download_urls,
            }
        )

        num_dict_found += 1

    for ext in SUPPORTED_EXTENSIONS:
        item = SUPPORTED_EXTENSIONS[ext]
        needed_files.append(os.path.join(output_dir, f"all-{item['dir']}.zip"))

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
    header = "| Number | Name | "  # " Description | Source | Target | Owner/Editor | Definitions | " + " | ".join(types)]
    seperator = "| --- | --- | "  # " --- | --- | --- | --- | --- |" + " --- |" * len(extensions)]

    if "desc" in columns:
        header += "Description |"
        seperator += " --- |"

    if "source" in columns:
        header += "Source |"
        seperator += " --- |"

    if "target" in columns:
        header += "Target |"
        seperator += " --- |"

    if "owner" in columns:
        header += "Owner/Editor |"
        seperator += " --- |"

    if "version" in columns:
        header += "Version |"
        seperator += " --- |"

    if "definition" in columns:
        header += "# Definitions |"
        seperator += " ---: |"  # Right align number of definitions

    header += " | ".join(types) + " |"
    seperator += " --- |" * len(extensions)

    header += " Number |"
    seperator += " --- |"

    markdown = [header, seperator]

    for num, entry in enumerate(data, start=1):
        download_links = " | ".join([f"[Download]({entry['Download'][ext]})" if entry['Download'][ext] else "N/A" for ext in extensions])

        line = f"| {num} | {entry['Name']} | "

        if "desc" in columns:
            line += f"{entry['Description']} |"

        if "source" in columns:
            line += f"{entry['Source']} |"

        if "target" in columns:
            line += f"{entry['Target']} |"

        if "owner" in columns:
            line += f"{entry['Owner/Editor']} |"

        if "version" in columns:
            line += f"{entry['Version']} |"

        if "definition" in columns:
            line += f"{entry['Definitions']:,} |"

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
