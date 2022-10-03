rem Example: createmobi.bat Tu-dien-Tong-hop-Phat-hoc
mobigen.exe -unicode -s0 ../dict/%1/%1.opf
move ..\dict\%1\%1.mobi ..\output\kindle
