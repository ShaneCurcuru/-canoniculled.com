#!/usr/bin/env ruby
# Canonical examples of structured data parsing/writing
require 'yaml'
require 'json'
require 'mail'
require 'csv'
require 'stringio'
require 'zlib'

DIR = '~/src/g/canoniculled.com/ruby/'

# CSV to array of hashes
def csv2hash(file)
  # read file into body
  csv = CSV.new(body, :headers => true, :header_converters => :symbol, :converters => :all)
  csv.to_a.map {|row| row.to_hash }
end

# CSV filter: omit rows matching regex into new csv
# regex like /201[45678]/
def csvfilter(file, regex)
  outcsv = CSV.open("#{file}.csv", 'w')
  # CSV.foreach processes one row at a time (saves memory)
  CSV.foreach(file, headers: true) do |row|
    if row['version'] =~ regex
      outcsv << row
    end
  end
  outcsv.close
end

# Write array with predefined headers to CSV
def ary2csv(ary, file)
  CSV.open(File.join("#{dir}", "#{file}"), "w", headers: %w( date who subject messageid committer question ), write_headers: true) do |csv|
    ary.each do |h|
      csv << [h[:date], h[:who], h[:subject], h[:messageid], h[:committer], h[:type] ]
    end
  end
end

# Read specific detail from a YAML file and dump as JSON
def yaml2json(filename)
  y = YAML.load(File.read(filename))
  y = YAML.load_file(filename)
  vhosts = y['vhosts_whimsy::vhosts::vhosts']['whimsy-vm-443']['authldap']
  
  File.open("#{filename}.out", "w") do |f|
    f.write(YAML.dump(y))
  end
  
  puts JSON.pretty_generate(vhosts)
end

# New-BSD License http://dan.doezema.com/2012/04/recursively-sort-ruby-hash-by-key/
class Hash
  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end
end

# Turn nested JSON hashes into sorted .out
def sortjsonfile(filename)
  h = JSON.parse(File.read(filename))
  File.open("#{filename}.out", "w") do |f|
    f.write(JSON.pretty_generate(h.sort_by_key(true)))
  end
end

# Process a directory of files of certain extension
def scan_dir(dir)
  headers = []
  Dir["#{dir}/**/*#{EXTENSION}".untaint].each do |f|
    scan_file(f.untaint, headers)
  end
  return headers
end

# Read an MBOX file - or .gz - into array of messages, and process headers vs. bodies (just raw, not MIME)
# DEPRECATED: See instead https://github.com/apache/whimsy/blob/master/tools/ponypoop.rb
def scan_file(f, headers)
  begin
    mbox = File.read(f)
    if f.end_with? GZ_EXT
      stream = StringIO.new(mbox)
      reader = Zlib::GzipReader.new(stream)
      mbox = reader.read
      reader.close
      stream.close rescue nil
    end
    mbox.force_encoding Encoding::ASCII_8BIT
    messages = mbox.split(/^From .*/)
    messages.shift # Drop first item (not a message)
  rescue Exception => e
    puts "ERROR:scan_file(#{f}) #{e}"
    return
  end    
  begin
    messages.each do |message|
      header = {}
      catch :headerend do
        lines = message.split(/\n/)
        lines.shift # Drop first bogus line stored in some MBOX formats
        lines.each do |line|
          throw :headerend if line == ""
          case line
          when /^Subject: (.*)/
            header[:subject] = "#{$1}"
          when /^From: (.*)/
            header[:from] = "#{$1}"
          when /^Date: (.*)/
            header[:date] = "#{$1}"
          when /^List-Id: <(.*)>/
            header[:listid] = "#{$1}"
          when /^Message-ID: <(.*)>/
            header[:messageid] = "#{$1}"
          when /^In-Reply-To: <(.*)>/
            header[:inreplyto] = "#{$1}"
          end
        end
      end
      headers << header
    end
    return
  rescue Exception => e
    puts e # TODO rationalize error processing
    return ["ERROR:scan_file(#{f}) #{e.message[0..255]}", "\t#{e.backtrace.join("\n\t")}"]
  end
end

