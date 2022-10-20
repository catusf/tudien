# Example: ./bin/createmobi.sh Ngu-vung-Danh-tu-Thien-hoc

wine ./bin/mobigen.exe -unicode -s0 ./dict/$1/$1.opf

mv ./dict/$1/$1.mobi ./output/kindle/
