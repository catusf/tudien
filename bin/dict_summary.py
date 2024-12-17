"""Generates summary of available dictionaries"""

import argparse
import json
import os

import langcodes

DOWNLOAD_TAG = "v4.0"  # Set the GitHub tag version that asscociates with the release


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
  "dictd.zip": "DictD",
  "dsl.dz": "Lingvo (DSL)",
  "epub": "EPUB",
  "kobo.zip": "Kobo",
  "mobi": "Kindle (.mobi)",
  "stardict.zip": "StartDict",
  "yomitan.zip": "Yomitan",
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
    download_url = f"https://github.com/catusf/tudien/releases/tag/{tag_download}/{filebase}.{ext}"
    download_links[ext] = download_url

  return download_links


def generate_summary(dict_dir):
  """Generate a list of dictionaries containing metadata for each .dfo file."""
  print(f"Generating summary data for {dict_dir}")

  data = []

  for filename in os.listdir(dict_dir):
    if filename.endswith(".dfo"):
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

    # Save the list of dictionaries as a JSON file
    json_path = os.path.join(dict_dir, "dict_summary.json")
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(data, json_file, ensure_ascii=False, indent=4)

        print(f"Data file writtend to '{json_path}'.")

    return data


def generate_markdown_table(data, extensions, columns):
  """Generate a markdown table from the data."""
  print(f"Generating report for {len(data)} dictionaries for {extensions}")

  types = [SUPPORTED_EXTENSIONS[ext] for ext in extensions]
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
    header += "Definitions |"
    seperator += " --- |"

  header += " | ".join(types) + " |"
  seperator += " --- |" * len(extensions)

  markdown = [header, seperator]

  for entry in data:
    download_links = " | ".join([f"[Download]({entry['Download'][ext]})" for ext in extensions])

    line = f"| {entry['Number']} | {entry['Name']} | "

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

    markdown.append(line)

  return "\n".join(markdown)


def main():
    """Main function to parse arguments and run the processes."""  # noqa: D202, D401

    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Generate a dictionary summary.")
    parser.add_argument("--dict_dir", type=str, nargs="?", default="dict", help="The directory containing the dictionary files (default is 'dict').")
    parser.add_argument("--outfile", type=str, nargs="?", default="dict_summary.md", help="The output report file name (default is 'dict_summary.md').")
    parser.add_argument("--extensions", type=str, nargs="?", default=None, help="The extensions that need included in the report. None means all.")
    parser.add_argument("--columns", type=str, nargs="?", default=None, help="The columns that will be kept (Other than the download links).")
    parser.add_argument("--read-only", choices=["yes", "no"], default="yes", required=False, help="Read data or create it.")

    args = parser.parse_args()

    # Generate the summary data and save it as a JSON file
    ext_str = args.extensions
    col_str = args.columns
    read_only = args.read_only
    dict_dir = args.dict_dir
    outfile = args.outfile

    extensions = list(SUPPORTED_EXTENSIONS.keys()) if not ext_str else [item.strip() for item in ext_str.split(",")]
    columns = list(COLUMNS.keys()) if not col_str else [item.strip() for item in col_str.split(",")]
    
    if read_only == "no":
        data = generate_summary(dict_dir)
    else:
        json_path = os.path.join(dict_dir, "dict_summary.json")
        with open(json_path, 'r', encoding='utf-8') as json_file:
            data = json.load(json_file)

    # Generate the markdown table from the JSON data
    markdown_table = generate_markdown_table(data, extensions, columns)

    # Save the markdown table to a .md file
    markdown_file = os.path.join(dict_dir, outfile)
    with open(markdown_file, 'w', encoding='utf-8') as file:
        file.write(markdown_table)
        print(f"Data file written to: {markdown_file}")

    print(f"Summary markdown file '{outfile}' has been generated.")


if __name__ == "__main__":
  main()
