#!/usr/bin/env ruby
module GHTools
  DESCRIPTION = <<-HEREDOC
  ghtools: Various GitHub Pages related tools
    Provide overview of various Jekyll _config.yml files
    
  HEREDOC
  extend self
  require 'json'
  require 'optparse'
  require 'csv'
  require 'yaml'

  # Simplistic list of Jekyll/GHPages related fields to pull from YAMLs
  CONFIG_FIELDS = %w(repository title description tagline url theme remote_theme permalink logo google_analytics)
  ALT_ANALYTICS = %w(ga_username) ## TODO Read alternate analytics tags
  CONFIG_FIELDS_HEADERS = %w(dir repository title description tagline url theme remote_theme permalink logo google_analytics)
  REPOLIST_FIELDS = %w(repo homepage license description fork updated_at has_pages default_branch)

  # Scan local tree of repos for config files
  def get_local_configs(srcroot, findname)
    configs = Hash.new{ |h,k| h[k] = Hash.new() }
    # For each dir with a found file, find and process selected config data
    Dir[File.join(Dir::home, srcroot, "**", findname)].each do |f|
      config = YAML.load(File.read(f), aliases: true)
      rdir = File.dirname(f)
      # Find most likely root repo dir name
      rdir = File.dirname(rdir) if "docs".eql?(File.basename(rdir))
      rdir = File.basename(rdir)
      configs[rdir] = {}
      CONFIG_FIELDS.each do |field|
        configs[rdir][field] = config[field] if config.has_key?(field)
      end
    end
    return configs
  end

  # Dump select config file fields to csv
  def write_local_configs(configs, outfile)
    CSV.open(outfile, "w", headers: CONFIG_FIELDS_HEADERS, write_headers: true) do |csv|
      configs.each do |repo, r|
        csv << [repo, r['repository'], r['title'], r['description'], r['tagline'], r['url'], r['theme'], r['remote_theme'], r['permalink'], r['logo'], r['google_analytics'] ]
      end
    end
  end

  # Append local config fields to ghrepolist json non-forks; overwrites file
  def add_local_configs(infile, configs, outfile)
    repos = JSON.parse(File.read(infile))
    repos.each do |repo|  
      next if repo['fork']
      if configs.has_key?(repo['name']) # Note: misses differently-named local clones
        repo.store('local', configs[repo['name']])
      end
      puts "DEBUGd #{repo['name']}"
    end
    File.open(outfile, "w") do |f|
      f.write(JSON.pretty_generate(repos))
    end
  end

  # Scan GitHub Repositories JSON and dump selected fields as CSV
  # https://api.github.com/users/ShaneCurcuru/repos?per_page=100
  def skim_ghrepolist(infile, outfile)
    repos = JSON.parse(File.read(infile))
    CSV.open(outfile, "w", headers: REPOLIST_FIELDS, write_headers: true) do |csv|
      repos.each do |r|
        #unless r['fork']
          csv << [r['full_name'], r['homepage'], r['license'] ? r['license']['spdx_id'] : "", r['description'], r['fork'], r['updated_at'], r['has_pages'], r['default_branch'] ]
        #end
      end
    end
  end

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
    # options = parse_commandline
    # options[:infile] ||= 'githublist.json'
    # options[:out] ||= 'githublist.csv'
    puts "DEBUG START"
    ghrepos = "/Users/curcuru/src/ghrepos.json"
    srcroot = "src/g"
    findname = "_config.yml"
  
    #skim_ghrepolist(ghrepos, "/Users/curcuru/src/ghrepos.csv")
    #write_local_configs(get_local_configs(srcroot, findname), 'ghlocal.csv')
    add_local_configs(ghrepos, get_local_configs(srcroot, findname), ghrepos + "-out")
    puts "DEBUG END"
  end
end