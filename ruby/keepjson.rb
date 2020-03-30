#!/usr/bin/env ruby
# Transform Google Keep JSON output, with options
module KeepJSON
  DESCRIPTION = <<-HEREDOC
  keepjson: Parse an exported Google Takeout archive dir of Keep entries
  Scan for certain tags, and output a single JSON with custom processing.
  Defaults to processing . and outputs keep2csv.json
  HEREDOC
  extend self
  require 'json'
  require 'optparse'
  require 'date'

  ICON = 'icon'
  DATE = 'date'
  ORDER = 'order'
  FLAGMAP = {
    'i' => ICON,
    'd' => DATE,
    'o' => ORDER
  }

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
      # Copy over only relevant data, as flat hash
      keep_item = {}
      keep_item['title'] = note['title']
      if note.has_key?('annotations')
        keep_item['preview'] = note['annotations'][0]['description']
        keep_item['htmltitle'] = note['annotations'][0]['title']
        keep_item['title'] = keep_item['htmltitle'] if keep_item['title'].empty? # Fallback to Use web page title if no user-provided title
        keep_item['url'] = note['annotations'][0]['url']
      end
      # Custom processing for the user-provided content block
      tmp = note['textContent'].lines # Exported as URL/n/nText Content
      tmp.length > 1 ? keep_item['content'] = tmp[2].strip : keep_item['content'] = tmp.strip
      flags = keep_item['content'].split('~')
      if flags.length > 1
        # Custom processing for ~end:of the user-provided content block
        keep_item['content'] = flags[0]
        flags.drop(1).each do |flag|
          x = flag.split(':')
          if x.length > 1
            FLAGMAP.has_key?(x[0]) ? keep_item[FLAGMAP[x[0]]] = x[1] : keep_item[x[0]] = x[1]
          else
            keep_item[ICON] = x[0] # Default flag
          end
        end
      end
      if keep_item.has_key?(DATE)
        keep_item['displaydate'] = DateTime.parse(keep_item[DATE]).strftime('%d-%b-%Y')
      end
      unless notags
        keep_item['labels'] = []
        if note.has_key?('labels')
          note['labels'].each do |h|
            keep_item['labels'] << h['name']
          end
        end
      end
      #keep_item['textContent'] = tmp.clone # DEBUG
      #keep_item['color'] = note['color'] # DEBUG
      #keep_item['file'] = f # DEBUG
      data << keep_item unless keep_item['title'].empty?
    rescue StandardError => e
      puts ["ERROR:parse_keep(#{f}) #{e.message[0..255]}", "\t#{e.backtrace.join("\n\t")}"]
    end
  end

  # Read a directory of Google Keep Takeout *.json files and return array of hashes
  # @param d directory path to /Takeout/Keep
  def process_keep(d, tag, notags)
    data = []
    files = Dir[File.join(d, '*.json').untaint]
    puts "Processing #{files.length} files from #{d}"
    files.each do |f|
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
    options[:out] ||= 'keepjson.json'
    puts "Processing: #{options[:dir]}/*.json into #{options[:out]}}"
    results = process_keep(options[:dir], options[:tag], options[:notags])
    # Sort the output results when date or order provided
    # Sort when order|date provided
    dated, other = results.partition{ |x| x.has_key?('date') }
    dated.sort! {|x,y| y['date'] <=> x['date']}
    File.open("#{options[:out]}", "w") do |f|
      f.puts JSON.pretty_generate(other + dated)
    end
  end
end


