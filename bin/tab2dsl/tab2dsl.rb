#!/usr/bin/ruby -KuU
# encoding: utf-8

# requires: dictzip

require 'optparse'
require 'json'

require_relative '../lib/dsl_lib.rb'

def interactive_mode(dict_source)
  if !dict_source
    puts "DSL file name:"
    dict_source = gets.chomp
  end

  tab_data = read_dict_source(dict_source)
  dsl_name = get_dict_name(dict_source)

  puts "Dictionary name:"
  dict_name = $stdin.gets.chomp
  puts "Index Language (from):"
  index_lang = $stdin.gets.chomp
  puts "Contents Language (to):"
  contents_lang = $stdin.gets.chomp

  header_stuff = format_header(dict_name, index_lang, contents_lang)

  puts "Thank you. Your dictionary header looks like this:\n\n"
  puts header_stuff
  puts "Please wait. Processing dictionary data..."

  dict_content = format_dictionary(tab_data)
end

def format_dictionary(tab_data)
  dict_content = ""

  tab_data.each_line do |line|
    if skip_lines(line)
      next
    end
    if line.include? "\t"
      line = line.gsub(/\[/, "\\[").gsub(/\]/, "\\]")

      tab1,tab2 = line.chomp.split("\t")
      tab2_format = tab2.gsub(tab1, "[i]~[/i]")
      dict_entry = tab1 + "\n" + tab2 + "\n\t[m1][b]" + tab1 + "[/b][/m]\n\t[m1]" + tab2_format + "[/m]\n\n"
      dict_content << dict_entry
    end
  end
  dict_content
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: tab2dsl.rb [options] [filename]"

  opts.on('-d', '--debug', 'Output dictionary text to stdin (without creating compressed file)') { options[:debug] = true }
  opts.on('-f', '--from-lang LANG', 'Name of source language') { |v| options[:from_lang] = v }
  opts.on('-m', '--monolingual', 'Only provide unidirectional lookups (default is bidirectional)') { options[:monolingual] = true }
  opts.on('-n', '--dict-name NAME', 'Full name of dictionary') { |v| options[:dict_name] = v }
  opts.on('-t', '--to-lang LANG', 'Name of target language') { |v| options[:to_lang] = v }
  opts.on('-s', '--stoplist LANG', 'Specify a stoplist language to filter keywords') { |v| options[:stoplist] = v }
  opts.on('-S', '--stop-dir DIR', 'Specify path of stoplist directory') { |v| options[:stopdir] = v }

end.parse!

if ARGV[0] then dict_source = ARGV[0] end

tab_data = read_dict_source(dict_source)
dsl_name = get_dict_name(dict_source)
header_stuff = get_header(options)
dict_content = format_dictionary(tab_data)

handle_output(options, dsl_name, header_stuff, dict_content)
