# 1. Install CMake, compiler (g++), and dependencies (expat is usually required for xdxf)
sudo apt-get update && \
sudo apt-get install -y cmake build-essential libexpat1-dev zlib1g-dev

# 2. Clone the specific tag
git clone --depth 1 --branch rev33 https://github.com/soshial/xdxf_makedict.git

# Adds a .gitignore to ignore build/ directory
echo "build/" > xdxf_makedict/.gitignore
echo ".gitignore" >> xdxf_makedict/.gitignore

git clone --depth 1 https://github.com/Markismus/LanguageFilesPocketbookConverter.git

# 3. Enter the directory
cd xdxf_makedict

# 4. Create a clean build directory (Best Practice)
mkdir build
cd build

# 5. Configure with CMake (pointing to the parent directory where source is)
cmake ..

# 6. Build
make

# 7. Install (needs sudo)
sudo make install

# 8. Test
makedict --help

# makedict -i dictd -o xdxf /workspaces/tudien/output/Viet-Trung.index --work-dir output/xdxf
# wine LanguageFilesPocketbookConverter/converter.exe /workspaces/tudien/output/xdxf/Viet-Trung/dict.xdxf ./LanguageFilesPocketbookConverter/en/
# mv output/xdxf/Viet-Trung/dict.dic output/Viet-Trung.dic