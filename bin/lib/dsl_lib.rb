def save_dsl(dsl_name, header_stuff, dict_content)
  File.open(dsl_name + ".dsl", "wt", encoding: "UTF-16LE") do |f|
    f << header_stuff
    f << dict_content
  end
end

def format_header(dict_name, index_lang, contents_lang)
  "#NAME \"#{dict_name}\"\n#INDEX_LANGUAGE \"#{index_lang}\"\n#CONTENTS_LANGUAGE \"#{contents_lang}\"\n\n"
end

def get_header(options)
  dict_name = "Dictionary Name"
  index_lang = "Source"
  contents_lang = "Target"
  if options[:dict_name]
    dict_name = options[:dict_name]
  end
  if options[:from_lang]
    index_lang = options[:from_lang]
  end
  if options[:to_lang]
    contents_lang = options[:to_lang]
  end

  format_header(dict_name, index_lang, contents_lang)
end

def zipsave(dsl_name, header_stuff, dict_content)
  save_dsl(dsl_name, header_stuff, dict_content)

  `dictzip #{dsl_name}.dsl`

  puts "Done! Your dictionary is now available in the file #{dsl_name}.dsl.dz"
end

def handle_output(options, dsl_name, header_stuff, dict_content)
  if options[:debug]
    puts header_stuff
    puts dict_content
  else
    zipsave(dsl_name, header_stuff, dict_content)
  end
end

def get_dict_name(dict_source)
  dsl_name = File.basename(dict_source, File.extname(dict_source))
end

def read_dict_source(dict_source)
  if !File.exist?(dict_source)
    abort(  "  Dictionary file not found: '#{dict_source}'")
  end
  File.read(dict_source)
end

def skip_lines(line)
  skip = false
  if line.match(/^==/)
    skip = true
  end
  if line.match(/^$/)
    skip = true
  end
  if line.match(/^\t/)
    skip = true
  end
  skip
end

def read_stoplist(options, lang)
  json = []
  stoplist_dir = ""

  if options[:stopdir]
    stoplist_dir = options[:stopdir]
  end

  stop_filename = stoplist_dir + lang + ".json"
  if !File.exist?(stop_filename)
    abort("  Stopfile not found: '#{stop_filename}'")
  end
  stopwords_file = File.read(stop_filename)
  JSON.parse(stopwords_file)
end

