#!/usr/bin/env ruby
# Transform Google Keep Takeout to JSON
module Keep2CSV
  DESCRIPTION = <<-HEREDOC
  keep2csv: Parse an exported Google Takeout archive dir of Keep entries
  Emit structured data of URLs, tags, titles, text as JSON
  Defaults to processing . and outputs keep2csv.json
  HEREDOC
  extend self
  require 'net/http'
  require 'nokogiri'
  require 'json'
  require 'optparse'

  # Parse one Keep note output file and aggregate into data
  # @param f filename to read
  # @param data hash, filled in as side effect
  def parse_keep(f, data)
    begin
      doc = Nokogiri::HTML(File.read(f))
      content = doc.css('.content').inner_html # Split the html data by <br><br>
      contents = content.split('<br><br>', 2)
      link = contents[0]
      title = doc.css('.title').text
      key = ''
      if link =~ /^http/i
        key = link
        data[key] = {}
        data[key]['title'] = title
      else # If not a URL, then use the typed in title
        key = title
        data[key] = {}
        data[key]['title'] = link
      end
      data[key]['d'] = contents
      if contents.length > 1
        data[key]['content'] = contents[1]
      else
        data[key]['content'] = '' # Ensure key is present
      end
      tags = []
      doc.css('.label-name').each do |n|
        tags << n.text
      end
      data[key]['tags'] = tags
    rescue StandardError => e
      data[f] = "ERROR #{e.message}"
    end
  end

  # Read a directory of Google Keep Takeout *.html files and return hash
  # @param d directory path to /Takeout/Keep
  def process_keep(d)
    data = {}
    Dir[File.join(d, '*.html').untaint].each do |f|
      parse_keep(f.untaint, data)
    end
    return data
  end

  # Precompute crossindex by all tags; side effect mutates input
  # @param data hash to add index to
  def crossindex(data)
    tagidx = {}
    data.each do |key, val|
      t = val['tags']
      if not (t.empty?)
        t.each do |tag|
          if not (tagidx.has_key?(tag))
            tagidx[tag] = []
          end
          tagidx[tag] << key
        end
      end
    end
    data['tagidx'] = tagidx
  end
  
  # ## ### #### ##### ######
  # Check commandline options (examplar code; overkill for this purpose)
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-dDIRECTORY', '--directory DIRECTORY', 'Directory to process (where you unzipped Keep Takeout data)') do |dir|
        if File.directory?(dir)
          options[:dir] = dir
        else
          raise ArgumentError, "-d #{dir} is not a valid directory" 
        end
      end
      opts.on('-oOUTFILE.JSON', '--out OUTFILE.JSON', 'Output filename to write as JSON detailed data') do |out|
        options[:out] = out
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
    puts "Processing: #{options[:dir]} into #{options[:out]}}"
    results = process_keep(options[:dir])
    crossindex(results)
    puts JSON.pretty_generate(results)
    File.open("#{options[:out]}", "w") do |f|
      f.puts JSON.pretty_generate(results)
    end
  end
end


