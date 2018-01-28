#!/usr/bin/env ruby
# Run svn blame on a directory and emit statistics
module WhoWrote
  DESCRIPTION = <<-HEREDOC
  whowrote: use svn blame to see who wrote what lines/files/revisions.
    Runs blame recursively, and saves a .json of statistics:
    {PATH => startDir, STATS => {}, DIRS => {}, FILES => {}, ERRORS => [] [, META => {}]}
    Also creates a .md file describing the highlights.
    
    TODO Need to add: skip lines of common license data in headers
  HEREDOC
  extend self
  require 'json'
  require 'open3'
  require 'optparse'
  
  # Directories and SVN control files to skip silently
  EXCLUDE_FILES = {
    '.' => '',
    '..' => '',
    '.svn' => '',
    '.DS_Store' => ''
  }
  # Non-text extensions to skip from http://apache.org/dev/svn-eol-style.txt
  EXCLUDE_EXTS = [ 
    /\.ai\z/i, /\.doc\z/i, /\.gif\z/i, /\.gz\z/i, /\.ico\z/i, /\.jpg\z/i, /\.ods\z/i, /\.pdf\z/i, /\.png\z/i, /\.swc\z/i, /\.tar\z/i, /\.tgz\z/i, /\.tif\z/i, /\.tiff\z/i, /\.xls\z/i, /\.zip\z/i
  ]
  # Keys within a dirBlame structure
  PATH = 'path'     # Absolute path of dir
  FILES = 'files'   # Array of fileBlames
  DIRS  = 'dirs'    # Array of subdirs dirBlames
  ERRORS = 'errors' # Array of errors encountered processing a dir
  STATS = 'stats'   # Annotation statsary of the dir's files (only)
  META = 'meta'     # Annotation statsary of the dir and subtree
  # Indexes into a process() userdata
  FILELINES = 0
  FILEREVS = 1
  # Indexes into a statsary usershash
  USERLINES = 0
  USERFILES = 1
  USERREVS = 2
  # Indexes into new_statsary - stats or meta arrays
  LINECT = 0
  FILECT = 1
  REVSARY = 2
  USERSHASH = 3
  
  # Create statsary for stats or meta
  # @return blank statsary [linect, filect, [revs], {stats of users}]
  def new_statsary()
    return [0, 0, [], {}] 
  end
  
  # Run svn blame on one file
  # @param path absolute path to a local svn checkout file
  # @return userdata from file as {usr: [0, [], []], ...} if successful
  # @return nil, "Error: path message" if error
  def process(path, user = nil, password = nil)
    return nil, 'ProcessError: path must not be nil' unless path
    cmd = ['svn', 'ann', '-x', '-b', path, '--non-interactive']
    if password
      cmd += ['--username', user, '--password', password, '--no-auth-cache']
    end
    out, err, status = Open3.capture3(*cmd)
    if !(status.success?)
      return nil, "SVNError: #{path} #{err}"
    end

    out.force_encoding(Encoding::UTF_8) # Avoid encoding errors
    fileBlame = Hash.new{|h,k| h[k] = [0, {}] }
    begin
      out.lines.map(&:chomp).each do |l|
        itm = l.strip.split(' ', 3)
        fileBlame[itm[1]][FILELINES] += 1
        fileBlame[itm[1]][FILEREVS][itm[0]] = nil # Hashes ensure uniqueness
      end
    rescue StandardError => e
      return nil, "StandardError: #{path} #{e.message}"
    end
    # Simplify revision hash into array [0, {}] -> [0, []] for storage
    fileBlame.each do |usr, data|
      fileBlame[usr][FILEREVS] = data[FILEREVS].keys
    end
    return fileBlame
  end
  
  # Traverse dir tree recursively, saving dirBlame data
  # @param startDir absolute path to a svn checkout directory
  # @param excludeNames array of files or dir names to silently skip
  # @param excludeExt Regexp to match with filename regexes to exclude
  # @return hash of our dirBlame
  def traverse(startDir, excludeNames = EXCLUDE_FILES, excludeExt = Regexp.union(EXCLUDE_EXTS), user = nil, password = nil)
    traverse = {PATH => startDir, DIRS => {}, FILES => {}, ERRORS => []}
    Dir.foreach(startDir) do |d|
      next if excludeNames.has_key?(d)
      path = File.join(startDir, d)
      if File.directory?(path)
        traverse[DIRS][path] = traverse(path, excludeNames, excludeExt, user, password)
      else
        if excludeExt =~ path
          traverse[ERRORS] << "Excluded: #{path}"
          next
        end
        fileBlame, err = process(path, user, password)
        fileBlame ? traverse[FILES][path] = fileBlame : traverse[ERRORS] << err
      end
    end
    return traverse
  end
  
  # Annotate stats of our subdirs into a meta
  # @param subdirs hash of subdirs listing
  # @param stats array of our own stats entry
  # @return new_statsary for the dir tree
  def meta(subdirs, stats)
    meta = new_statsary
    # Start with stats (i.e. the rollup of files within this dir), if any
    if stats
      meta[LINECT] = stats[LINECT]
      meta[FILECT] = stats[FILECT]
      # NOTE: deep copy needed, since we're later changing our meta
      meta[REVSARY] = stats[REVSARY].dup
      stats[USERSHASH].each do |usr, data| # process() userdata = [int, [], []]
        meta[USERSHASH][usr] = []
        meta[USERSHASH][usr][USERLINES] = stats[USERSHASH][usr][USERLINES]
        meta[USERSHASH][usr][USERFILES] = stats[USERSHASH][usr][USERFILES].dup
        meta[USERSHASH][usr][USERREVS] = stats[USERSHASH][usr][USERREVS].dup
      end
    end
    # Add in the meta (if present) or stats from each immediate subdir
    if subdirs
      subdirs.each do |path, subdir|
        subdir.has_key?(META) ? addStats = subdir[META] : addStats = subdir[STATS]
        meta[LINECT] += addStats[LINECT]
        meta[FILECT] += addStats[FILECT]
        meta[REVSARY] = meta[REVSARY].concat(addStats[REVSARY]).uniq
        addStats[USERSHASH].each do |usr, data|
          if meta[USERSHASH].has_key?(usr) # .concat.uniq to existing userdata
            meta[USERSHASH][usr][USERLINES] += data[USERLINES]
            meta[USERSHASH][usr][USERFILES] = meta[USERSHASH][usr][USERFILES].concat(data[USERFILES]).uniq
            meta[USERSHASH][usr][USERREVS] = meta[USERSHASH][usr][USERREVS].concat(data[USERREVS]).uniq
          else # Dup a new userdata
            meta[USERSHASH][usr] = data.dup
          end
        end
      end
    end
    return meta
  end
  
  # Annotate statistics of directory's files into stats
  # @param blames hash for a single directory
  # @return new_statsary for the immediate dir
  def stats(blames)
    stats = new_statsary
    stats[USERSHASH] = Hash.new{|h,k| h[k] = [0, [], []] }
    if blames[FILES]
      blames[FILES].each do |path, fileBlame|
        fileBlame.each do |usr, data| # userdata [int [], []]
          stats[FILECT] += 1
          stats[LINECT] += data[FILELINES]
          stats[REVSARY].concat(data[FILEREVS])
          stats[USERSHASH][usr][USERLINES] += data[FILELINES]
          stats[USERSHASH][usr][USERREVS].concat(data[FILEREVS])
          stats[USERSHASH][usr][USERFILES] << path
        end
      end
      stats[REVSARY].uniq!
      stats[USERSHASH].each do |usr, data|
        data[USERREVS].uniq!
      end
    end
    return stats 
  end
  
  # Annotate a tree of dirBlame data recursively, depth-first
  # @param blames hash for a specific directory; modified in place
  # @return blames annotated (for chaining) 
  def annotate(blames)
    blames[STATS] = stats(blames)
    if blames[DIRS].empty?
      return
    else
      blames[DIRS].each do |path, dirBlame|
        annotate(dirBlame)
      end
      blames[META] = meta(blames[DIRS], blames[STATS])
    end
    return blames
  end
  
  # Crawl blametree and emit markdown string
  # @param annotated dirBlame data
  # @param sortby for user table: LINECT | FILECT | USERREVS
  # @param userrows num rows in per-dir user tables (or ALLROWS/NOROWS)
  # @return String of lines of markdown
  def to_markdown(dirBlame, sortby = LINECT, userrows = 5)
    report = "# #{dirBlame[PATH]}\n\n"
    blame = dirBlame.has_key?(META) ? dirBlame[META] : dirBlame[STATS]
    if blame[LINECT] > 0
      report << hash_to_table(blame, sortby, userrows)
    end
    report << "\n\n"
    if dirBlame.has_key?(DIRS)
      dirBlame[DIRS].each do |dir, ent|
        report << to_markdown(ent, sortby, userrows)
      end
    end
    return report << "\n"
  end
  
  ALLROWS = -1
  NOROWS = 0
  # Emit markdown table of a dirBlame
  # @param annotated dirBlame data (either a meta or a stats)
  # @param sort key for user table: LINECT | FILECT | REVSARY
  # @param userrows num rows in per-dir user tables (or ALLROWS / NOROWS)
  # @return String of lines of markdown
  def hash_to_table(hash, sortby, userrows)
    sorts = ['lines', 'files', 'revs']
    numuser = (userrows == ALLROWS) ? 'displaying all rows' : "displaying top #{userrows} rows out of #{hash[USERSHASH].length}"
    report = "_(Sorted by #{sorts[sortby]}, #{numuser})_\n"
    report << "\n| User | Lines (%) | Files (%) | Revisions (%) |\n| ---- | ---------: | ---------: | -------------: |\n"
    begin
      report << "| **Totals** | **#{hash[LINECT]}** | **#{hash[FILECT]}** | **#{hash[REVSARY].length}** |\n"
      if userrows == NOROWS then return report end
      row = 0
      hash[USERSHASH].sort_by{
        |k, v| 
        (sortby == LINECT) ? v[sortby] : v[sortby].length
      }.reverse.to_h.each do |usr, data|
        if userrows != ALLROWS
          row += 1
          if row > userrows then break end
        end
        stats = [ 
          ((data[LINECT].to_f / hash[LINECT])*100).round(0),
          ((data[FILECT].length.to_f / hash[FILECT])*100).round(0),
          ((data[USERREVS].length.to_f / hash[REVSARY].length)*100).round(0)
        ]
        report << "| #{usr} | _(%.0f%%)_  #{data[LINECT]} | _(%.0f%%)_  #{data[FILECT].length} | _(%.0f%%)_  #{data[USERREVS].length} |\n" % stats
      end
    rescue StandardError => e
      report << "\n\n**StandardError:** #{e.message}\n\n"
    end
    return report
  end
  
  # ## ### #### ##### ######
  # Check commandline options (examplar code; overkill for this purpose)
  def parse_commandline
    options = {}
    OptionParser.new do |opts|
      opts.on('-h') { puts "#{DESCRIPTION}\n#{opts}"; exit }
      opts.on('-dDIRECTORY', '--directory DIRECTORY', 'Absolute directory to run svn blame recursively on (use with -o, -m)') do |dir|
        if File.directory?(dir)
          options[:dir] = dir
        else
          raise ArgumentError, "-d #{dir} is not a valid directory" 
        end
      end
      opts.on('-oOUTFILE.JSON', '--out OUTFILE.JSON', 'Output filename to write as JSON detailed data') do |out|
        options[:out] = out
      end
      opts.on('-iINFILE.JSON', '--in INFILE.JSON', 'Input JSON filename containing previously generated data (use with -m only)') do |infile|
        options[:infile] = infile
      end
      opts.on('-mOUTFILE.MD', '--markdown OUTFILE.MD', 'Output filename to write as Markdown synopsis (default: whowrote.md)') do |markdown|
        options[:markdown] = markdown
      end
      opts.on('-r5', '--rows 5', Integer, 'Number of rows for each dir user table (default: 5)') do |userrows|
        options[:userrows] = userrows.to_i
      end
      opts.on('-sSORT', '--sort SORTOPT', Integer, 'How to sort user tables: 0=lines (default) | 1=files | 2=revs') do |sortby|
        options[:sortby] = sortby.to_i
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
    options[:markdown] ||= 'whowrote.md'
    options[:userrows] ||= 5
    options[:sortby] ||= 0

    if options[:dir]
      options[:out] ||= 'whowrote.json'
      puts "Processing: #{options[:dir]} into #{options[:out]} and #{options[:markdown]}"
      whowrote = annotate(traverse(options[:dir]))
      File.open("#{options[:out]}", "w") do |f|
        f.puts JSON.pretty_generate(whowrote)
      end
      File.open("#{options[:markdown]}", "w") do |f|
        f.puts to_markdown(whowrote, options[:sortby], options[:userrows])
      end
      
    elsif options[:infile]
      puts "Processing: #{options[:infile]} into #{options[:markdown]}"
      whowrote = JSON.parse(File.read(options[:infile]))
      File.open("#{options[:markdown]}", "w") do |f|
        f.puts to_markdown(whowrote, options[:sortby], options[:userrows])
      end
      
    else
      raise ArgumentError, "Required: either -d /absolute/path or -i input.json"
    end
  end
end
