for f in "./ext-dict/*.tab" do ./bin/tab_stats.py $f done

mv ext-stardict-vi/*/*.tab ./ext-dict

cat /workspaces/tudien/dict/TudienAnhVietBeta.tab /workspaces/tudien/ext-dict/star_vietanh.tab > /workspaces/tudien/dict/TudienAnhVietAnh.tab

