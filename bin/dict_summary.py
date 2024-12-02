import os
import json
import argparse
import glob

# Language code to Vietnamese name mapping
language_names = {
    'vi': 'Tiếng Việt',
    'en': 'Tiếng Anh',
    'fr': 'Tiếng Pháp',
    'de': 'Tiếng Đức',
    'es': 'Tiếng Tây Ban Nha',
    'it': 'Tiếng Ý',
    'ja': 'Tiếng Nhật',
    'ko': 'Tiếng Hàn',
    'zh': 'Tiếng Trung',
    'ru': 'Tiếng Nga'
    # Add other languages as needed
}

def parse_dfo_file(dfo_path):
    """Parse the .dfo file and return its metadata as a dictionary."""
    metadata = {
        "Name": "",
        "Description": "",
        "Source": "",
        "Target": "",
        "Owner/Editor": "",
        "URL": "",
        "Version": ""  # Add version
    }

    try:
        with open(dfo_path, 'r', encoding='utf-8') as file:
            for line in file:
                if line.startswith("Name = "):
                    metadata["Name"] = line[len("Name = "):].strip()
                elif line.startswith("Description = "):
                    metadata["Description"] = line[len("Description = "):].strip()
                elif line.startswith("Source = "):
                    metadata["Source"] = line[len("Source = "):].strip()
                elif line.startswith("Target = "):
                    metadata["Target"] = line[len("Target = "):].strip()
                elif line.startswith("Owner/Editor = "):
                    metadata["Owner/Editor"] = line[len("Owner/Editor = "):].strip()
                elif line.startswith("URL = "):
                    metadata["URL"] = line[len("URL = "):].strip()
                elif line.startswith("Version = "):
                    metadata["Version"] = line[len("Version = "):].strip()  # Get the version
    except FileNotFoundError:
        print(f"Error: {dfo_path} not found.")
    
    return metadata

def count_lines_in_tab(tab_path):
    """Count the number of lines in the corresponding .tab file."""
    try:
        with open(tab_path, 'r', encoding='utf-8') as file:
            return sum(1 for _ in file)
    except FileNotFoundError:
        print(f"Error: {tab_path} not found.")
        return 0

extensions = [
    'dictd.zip', 'dsl.dz', 'epub', 'kobo.zip', 'mobi', 'stardict.zip', 'yomitan.zip'
]

folders = [
    'dictd', 'lingvo', 'epub', 'kobo', 'kindle', 'stardict', 'yomitan'
]

extension_names = [
    'DICT', 'Lingvo DSL', 'EPUB', 'Kobo', 'Kindle', 'StarDict', 'Yomitan/Yomichan'
]

def get_downloadable_files(filebase, tag_download, folder_path):
    """Return the downloadable file links based on the filebase name."""
    download_links = []

    for ext in extensions:
        # Generate the URL for the downloadable file
        download_url = f"https://github.com/catusf/tudien/releases/tag/{tag_download}/{filebase}.{ext}"
        download_links.append(download_url)
    
    return download_links

TAG_DOWNLOAD = "v3.0"

def generate_summary_data(dict_dir, output_dir):
    """Generate a list of dictionaries containing metadata for each .dfo file."""
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

        # Get the additional downloadable files
        download_urls = get_downloadable_files(filebase, TAG_DOWNLOAD, dict_dir)

        for extension in extensions:
            needed_files.append(os.path.join(output_dir, filebase + "." + extension))

        # Get full language names in Vietnamese
        source_full_name = language_names.get(metadata['Source'], f"Unknown ({metadata['Source']})")
        target_full_name = language_names.get(metadata['Target'], f"Unknown ({metadata['Target']})")

        # Append the data to the list
        data.append({
            "Number": len(data) + 1,  # Add numbering
            "Name": metadata['Name'],
            "Description": metadata['Description'],
            "Source": f"{source_full_name} ({metadata['Source']})",  # Full language name in Vietnamese
            "Target": f"{target_full_name} ({metadata['Target']})",  # Full language name in Vietnamese
            "Owner/Editor": metadata['Owner/Editor'],
            "URL": metadata['URL'],
            "Version": metadata['Version'],
            "Definitions": num_definitions,
            "Download": download_urls
        })

        num_dict_found += 1
    
    for folder in folders:
        needed_files.append(os.path.join(output_dir, f"all-{folder}.zip"))

    data.sort(key=lambda x: x['Source'])

    # Save the list of dictionaries as a JSON file
    with open(os.path.join(dict_dir, "dict_summary.json"), 'w', encoding='utf-8') as json_file:
        json.dump(data, json_file, ensure_ascii=False, indent=4)

    existing_files = sorted(glob.glob(os.path.join(output_dir, "*.*")))
    
    missing_files = sorted(set(needed_files) - set(existing_files))

    print("JSON file 'dict_summary.json' has been generated.")

    files_status = "# Status report\n\n"
    files_status += "## Counts\n\n"
    files_per_format = len(extensions)
    existing_dicts = (len(existing_files) - files_per_format)/ files_per_format
    missing_dicts = len(missing_files)/files_per_format
    mismatched_dicts = num_dict_found - (existing_dicts + missing_dicts)

    assert(num_dict_found == len(data))
    assert(files_per_format * (num_dict_found + 1) == len(needed_files))

    files_status += f"- There are **{len(data)}** dict files.\n\n"
    files_status += f"- Total NEEDED files: **{len(needed_files)}**\n\n"
    files_status += f"- Total EXISTING files: **{len(existing_files)}** "
    files_status += f"- or **{existing_dicts}** dictionaries. "
    if len(existing_files) % files_per_format != 0:
        files_status += "ABNORMAL NUMBER of files. Some dict has **missing format(s)**. Check missing files list for details.\n\n"
    else:
        files_status += "The number of files looks NORMAL.\n\n"

    files_status += f"- Total MISSING files: {len(missing_files)}** "
    files_status += f"(or **{missing_dicts}** dictionaries which is {'CORRECT' if mismatched_dicts==0 else 'IN-CORRECT'})\n\n"

    files_status += "# Errors\n"

    files_status_details = f"## Missing files list\n\n"
    for item in missing_files:
        files_status_details += f'\t{item}\n'

    print(files_status)
    return data, files_status + files_status_details

def generate_markdown_table(data, files_status):
    """Generate a markdown table from the data."""
    markdown = ["| STT | Tên từ điển | Mô tả | Ngôn ngữ gốc | Ngôn ngữ đích | Tác giả/Biên tập | Nguồn | Phiên bản | Số mục từ | " + " | ".join(extension_names)]
    markdown.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |" + " --- |" * len(extensions))

    for entry in data:
        download_links = " | ".join([f"[Download]({url})" for url in entry['Download']])
        markdown.append(f"| {entry['Number']} | {entry['Name']} | {entry['Description']} | {entry['Source']} | {entry['Target']} | {entry['Owner/Editor']} | [Reference]({entry['URL']}) | {entry['Version']} | {entry['Definitions']} | {download_links} |")
    
    markdown.append(files_status)

    return "\n".join(markdown)

def main():
    """Main function to parse arguments and run the processes."""
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Generate a dictionary summary.")
    parser.add_argument('--dict-dir', type=str, default='dict', 
                        help="The directory containing the dictionary files (default is 'dict').")
    parser.add_argument('--output-dir', type=str, default='output', 
                        help="The directory containing the output files (default is 'output').")
    args = parser.parse_args()

    # Generate the summary data and save it as a JSON file
    data, files_status = generate_summary_data(args.dict_dir, args.output_dir)

    # Generate the markdown table from the JSON data
    markdown_table = generate_markdown_table(data, files_status)


    # Save the markdown table to a .md file
    with open(os.path.join(args.dict_dir, "dict_summary.md"), 'w', encoding='utf-8') as file:
        file.write(markdown_table)

    print("Summary markdown file 'dict_summary.md' has been generated.")

if __name__ == "__main__":
    main()
