#!/usr/bin/env ruby
# Transform Google Keep JSON output
module KeepJSON
  DESCRIPTION = <<-HEREDOC
  keepjson: Parse an exported Google Takeout archive dir of Keep entries
  Scan for certain tags, and output a single JSON
  Defaults to processing . and outputs keep2csv.json
  HEREDOC
  extend self
  require 'json'
  require 'optparse'

  # Parse one Keep note output file and aggregate into data
  # @param f filename to read
  # @param data array, appended to as side effect
  # @param optional tag string to scan for; copy all if nil/blank
  def parse_keep(f, data, tag, notags)
    begin
      note = JSON.parse(File.read(f))
      skip = true
      if tag && ! tag.empty? && note.has_key?('labels')
        note['labels'].each do |h|
          if tag.eql?(h['name'])
            skip = false
            break
          end
        end
      end
      return if skip # Yes, the above is non-idomatic
      # Copy over only relevant data, as flat
      k = {}
      k['color'] = note['color']
      k['title'] = note['title']
      if note.has_key?('annotations')
        k['preview'] = note['annotations'][0]['description']
        k['htmltitle'] = note['annotations'][0]['title']
        k['url'] = note['annotations'][0]['url']
      end
      tmp = note['textContent'].lines # Exported as URL/n/nText Content
      k['content'] = tmp[2] if tmp.length > 1
      unless notags
        k['labels'] = []
        if note.has_key?('labels')
          note['labels'].each do |h|
            k['labels'] << h['name']
          end
        end
      end
      data << k
    rescue StandardError => e
      puts ["ERROR:parse_keep(#{f}) #{e.message[0..255]}", "\t#{e.backtrace.join("\n\t")}"]
    end
  end

  # Read a directory of Google Keep Takeout *.json files and return hash
  # @param d directory path to /Takeout/Keep
  def process_keep(d, tag, notags)
    data = []
    Dir[File.join(d, '*.json').untaint].each do |f|
      parse_keep(f.untaint, data, tag, notags)
    end
    return data
  end

  # ## ### #### ##### ######
  # Check commandline options (examplar code; overkill for this purpose)
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-dDIRECTORY', '--directory DIRECTORY', 'Directory to process (where you unzipped Keep Takeout .json data)') do |dir|
        if File.directory?(dir)
          options[:dir] = dir
        else
          raise ArgumentError, "-d #{dir} is not a valid directory" 
        end
      end
      opts.on('-oOUTFILE.JSON', '--out OUTFILE.JSON', 'Output filename to write as JSON detailed data') do |out|
        options[:out] = out
      end
      opts.on('-tTAG', '--tag TAG', 'Only copy notes that have TAG as a label') do |tag|
        options[:tag] = tag
      end
      opts.on('-nt', 'Do not output any TAGs') do |notags|
        options[:notags] = true
      end

      opts.on('-h', '--help', 'Print help for this program') do
        puts opts
        exit
      end
      begin
        opts.parse!
      rescue OptionParser::ParseError => e
        $stderr.puts e
        $stderr.puts opts
        exit 1
      end
    end
    return options
  end
  
  # ### #### ##### ######
  # Main method for command line use
  if __FILE__ == $PROGRAM_NAME
    options = parse_commandline

    options[:dir] ||= '.'
    options[:out] ||= 'keep2csv.json'
    puts "Processing: #{options[:dir]}/*.json into #{options[:out]}}"
    results = process_keep(options[:dir], options[:tag], options[:notags])
    File.open("#{options[:out]}", "w") do |f|
      f.puts JSON.pretty_generate(results)
    end
  end
end


