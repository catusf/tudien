import os
import json
import argparse

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

def get_downloadable_files(filebase, tag_download, folder_path):
    """Return the downloadable file links based on the filebase name."""
    download_links = []

    for ext in extensions:
        # Generate the URL for the downloadable file
        download_url = f"https://github.com/catusf/tudien/releases/tag/{tag_download}/{filebase}.{ext}"
        download_links.append(download_url)
    
    return download_links

TAG_DOWNLOAD = "v3.0"

def generate_summary(folder_path):
    """Generate a list of dictionaries containing metadata for each .dfo file."""
    data = []

    for filename in os.listdir(folder_path):
        if filename.endswith(".dfo"):
            filebase = filename[:-4]
            dfo_path = os.path.join(folder_path, filename)
            tab_path = os.path.join(folder_path, filebase + ".tab")

            # Parse the .dfo file
            metadata = parse_dfo_file(dfo_path)

            # Count lines in the corresponding .tab file
            num_definitions = count_lines_in_tab(tab_path)

            # Generate the download URL for the main file
            main_download_url = f"https://github.com/catusf/tudien/releases/tag/{TAG_DOWNLOAD}/all-kindle.zip"

            # Get the additional downloadable files
            download_urls = get_downloadable_files(filebase, TAG_DOWNLOAD, folder_path)

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

    # Save the list of dictionaries as a JSON file
    with open(os.path.join(folder_path, "dict_summary.json"), 'w', encoding='utf-8') as json_file:
        json.dump(data, json_file, ensure_ascii=False, indent=4)

    print("JSON file 'dict_summary.json' has been generated.")
    return data

def generate_markdown_table(data):
    """Generate a markdown table from the data."""
    markdown = ["| Number | Name | Description | Source | Target | Owner/Editor | URL | Version | Definitions | " + " | ".join(extensions)]
    markdown.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |" + " --- |" * len(extensions))

    for entry in data:
        download_links = " | ".join([f"[Download]({url})" for url in entry['Download']])
        markdown.append(f"| {entry['Number']} | {entry['Name']} | {entry['Description']} | {entry['Source']} | {entry['Target']} | {entry['Owner/Editor']} | {entry['URL']} | {entry['Version']} | {entry['Definitions']} | {download_links} |")
    
    return "\n".join(markdown)

def main():
    """Main function to parse arguments and run the processes."""
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Generate a dictionary summary.")
    parser.add_argument('dict_dir', type=str, nargs='?', default='dict', 
                        help="The directory containing the dictionary files (default is 'dict').")
    args = parser.parse_args()

    # Generate the summary data and save it as a JSON file
    data = generate_summary(args.dict_dir)

    # Generate the markdown table from the JSON data
    markdown_table = generate_markdown_table(data)

    count_info = f"\n\nCó tổng cộng **{len(data)}** file từ điển.\nTổng số file download **{len(data)*(len(extensions)+1)}**"

    markdown_table += count_info

    # Save the markdown table to a .md file
    with open(os.path.join(args.dict_dir, "dict_summary.md"), 'w', encoding='utf-8') as file:
        file.write(markdown_table)

    print("Summary markdown file 'dict_summary.md' has been generated.")

if __name__ == "__main__":
    main()
