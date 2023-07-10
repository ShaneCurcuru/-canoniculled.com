#!/usr/bin/env ruby
# Using GitHub APIs to export or massage your repo data
module GithubList
  DESCRIPTION = <<-HEREDOC
  githublist: parse /users/name and emit list(s).
    
    TODO everything else
  HEREDOC
  extend self
  require 'json'
  require 'optparse'
  require 'csv'

  # ## ### #### ##### ######
  # Check commandline options (examplar code; overkill for this purpose)
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-oOUTFILE.JSON', '--out OUTFILE.csv', 'Output filename to write as csv detailed data') do |out|
        options[:out] = out
      end
      opts.on('-iINFILE.JSON', '--in INFILE.JSON', 'Input JSON filename containing previously generated data (use with -m only)') do |infile|
        options[:infile] = infile
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
    options[:infile] ||= 'githublist.json'
    options[:out] ||= 'githublist.csv'
    repos = JSON.parse(File.read(options[:infile]))
    CSV.open(options[:out], "w", headers: %w( repo homepage license description fork updated_at ), write_headers: true) do |csv|
      repos.each do |r|
        #unless r['fork']
          csv << [r['full_name'], r['homepage'], r['license'] ? r['license']['spdx_id'] : "", r['description'], r['fork'], r['updated_at'] ]
        #end
      end
    end
    puts "done, total repo count = #{repos.length}"
  end 
end