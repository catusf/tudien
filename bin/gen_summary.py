import os
import subprocess
import argparse

def decompress_files(dict_dir):
    """Decompress all .bz2 files in the given directory."""
    for file_name in os.listdir(dict_dir):
        if file_name.endswith('.bz2'):
            file_path = os.path.join(dict_dir, file_name)
            print(f"Decompressing {file_path}...")
            
            # Run bzip2 command to decompress
            subprocess.run(['bzip2', '-dkf', file_path], check=True)
            
            print("done.")

def generate_report(dict_dir):
    """Generate the report using the dict_summary.py script."""
    print("Generating report...")
    subprocess.run(['python', 'bin/dict_summary.py', f'{dict_dir}'], check=True)
    print(f"Report generated at {dict_dir}/dict_summary.md")

def main():
    """Main function to parse arguments and run the processes."""
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Decompress .bz2 files and generate a report.")
    parser.add_argument('dict_dir', type=str, nargs='?', default='dict', 
                        help="The directory containing the .bz2 files (default is 'dict').")
    args = parser.parse_args()

    # Decompress files
    decompress_files(args.dict_dir)
    
    # Generate report
    generate_report(args.dict_dir)

if __name__ == "__main__":
    main()
