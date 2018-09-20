#!/usr/bin/env ruby
# Parse some common Netgear home router log entries into simplistic csv
require 'csv'
require 'json'
require 'set'

module NetgearLogs
  extend self
  # Constants relating to Netgear router log files
  SITE_ALLOWED = 'Site allowed'
  DHCP_ENTRY = 'DHCP'
  ADMIN_LOGON = 'Admin login'
  LOGLINE = /\[([^\]]+)]([^,]+)(, )?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday), (.*)/
  MATCH_IP = /(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}/
  MATCH_MAC = /(?:[[:xdigit:]]{2}([-:]))(?:[[:xdigit:]]{2}\1){4}[[:xdigit:]]{2}/
  
  # Hash key strings for analyzed entries
  DESC = 'desc'
  TYPE = 'type'
  DATA = 'data'
  IP_ADDR = 'ip'
  MAC_ADDR = 'mac'
  LOCAL_CLIENT = 'client'
  WEBSITE = 'site'
  WEEKDAY = 'wkdy'
  TIMEDATE = 'time'
  
  # Map local IP addr to a client MAC or name, if available
  # @param ip or mac address to check
  # @param ip_map of 127.0.0.1 => aa:bb:cc:macaddr
  # @param mac_map of aa:bb:cc:macaddr => clientname
  # @return MAC address or client name, if available
  def get_client(id, ip_map, mac_map)
    if /\./.match(id)
      if ip_map.has_key?(id)
        if mac_map.has_key?(ip_map[id])
          return mac_map[ip_map[id]]
        else
          return ip_map[id]
        end
      end
    elsif mac_map.has_key?(id)
      return mac_map[id]
    end
    return id
  end
  
  def get_who(entry)
    entry.has_key?(LOCAL_CLIENT) ? entry[LOCAL_CLIENT] : entry[IP_ADDR]
  end
  
  # Scan a file of log entries
  # @param f name of log file, in backwards chronological order (what copying log gives you)
  # @return array of lines, in reversed order
  def parse_logfile(f)
    lines = File.open(f).each_line.reverse_each.map(&:chomp)
    return lines
  end
  
  # Scan log entries and return array of analyzed entries as hashes
  # @param lines array of log lines (required; must be in time-order)
  # @param entries array of log entries (to aggregate to)
  # @param ip_map of 127.0.0.1 => aa:bb:cc:macaddr; is updated as we parse DHCP assignments
  # @param mac_map of aa:bb:cc:macaddr => clientname
  # @return hash of all entries in order
  def parse_entries(lines, entries = [], ip_map = {}, mac_map = {})
    lines.each do |line|
      LOGLINE.match(line) do |linematch|
        entry = {}
        ary = linematch[1].split(': ')
        entry[TYPE] = ary[0]
        entry[DATA] = (ary.length > 1 ? ary[1] : '')
        entry[DESC] = linematch[2].strip
        entry[WEEKDAY] = linematch[4]
        entry[TIMEDATE] = linematch[5]
        
        # Handle common types of log entries directly
        if entry[TYPE].start_with?(SITE_ALLOWED)
          entry[WEBSITE] = entry[DATA].split(':')[0]
          MATCH_IP.match(entry[DESC]) do |mip|
            entry[IP_ADDR] = mip[0]
            entry[LOCAL_CLIENT] = get_client(entry[IP_ADDR], ip_map, mac_map)
          end
          
        elsif entry[TYPE].start_with?(DHCP_ENTRY)
          MATCH_IP.match(entry[DATA]) do |mip|
            entry[IP_ADDR] = mip[0]
          end
          MATCH_MAC.match(entry[DESC]) do |mmac|
            entry[MAC_ADDR] = mmac[0]
          end
          entry[LOCAL_CLIENT] = get_client(entry[MAC_ADDR], ip_map, mac_map)
          # Also update our mapping going forward (changes caller's data)
          ip_map[entry[IP_ADDR]] = entry[MAC_ADDR]
          
        else # All other entries
          mtch = MATCH_IP.match(entry[DESC])
          if mtch
            entry[IP_ADDR] = mtch[0]
            entry[LOCAL_CLIENT] = get_client(entry[IP_ADDR], ip_map, mac_map)
          else # entries have either an IP or a MAC, not both
            mtch = MATCH_MAC.match(entry[DESC])
            if mtch
              entry[MAC_ADDR] = mtch[0]
              entry[LOCAL_CLIENT] = get_client(entry[MAC_ADDR], ip_map, mac_map)
            end
          end
        end
        
        entries << entry
      end
    end
    return entries
  end
  
  # Return report hash of some activities in analyzed logfile
  def report(entries, ip_map, mac_map)
    report = {}
    subtypes = %w(where dhcp admin)
    subtypes.each do |key|
      report[key] = Hash.new{ |h,k| h[k] = Set.new() }
    end
    report['who'] = Hash.new{ |h,k| h[k] = Hash.new() }
    report['other'] = []
    entries.each do |entry|
      client = get_who(entry)
      if entry.has_key?(WEBSITE)
#        report['who'][client] << entry[WEBSITE]
        # Cheap aggregation of TLDs TODO
        # OLD: report['who'][client] << entry[WEBSITE]
        tld = entry[WEBSITE].split('.').last(2).join('.')
        if !(report['who'][client].has_key?(tld))
          report['who'][client][tld] = Hash.new{ |h,k| h[k] = Set.new() }
        end
        report['who'][client][tld] << entry[WEBSITE]
        report['where'][entry[WEBSITE]] << client
      elsif entry[TYPE].start_with?(DHCP_ENTRY) # Log when it changed
        report['dhcp'][client] << "#{entry[IP_ADDR]}~#{entry[TIMEDATE]}"
      elsif entry[TYPE].start_with?(ADMIN_LOGON)
        report['admin'][client] << entry[TIMEDATE]
      else
        report['other'] << entry
      end
    end
    subtypes.each do |key|
      report[key].each do |h,k|
        report[key][h] = k.to_a.sort
      end
    end
    report['ip_map'] = ip_map
    report['mac_map'] = mac_map
    return report
  end
  
  # Analyze a logfile, inluding mapping IP/MACs to client names (if provided)
  def analyze_logfile(logfile:, ipmap_input: nil, macmap_input: nil, entriesfile: nil, reportfile:, ipmap_output: nil)
    # Read in provided mappings, if any
    if ipmap_input
      ip_map = JSON.parse(File.read(ipmap_input))
    end
    if macmap_input
      mac_map = JSON.parse(File.read(macmap_input))
    end
    ip_map ||= IPMAP.clone
    mac_map ||= MACMAP.clone
    
    # Parse the text log into entries
    lines = parse_logfile(logfile)
    entries = parse_entries(lines, [], ip_map, mac_map)
    
    # Create a condensed report, and output files requested
    rpt = report(entries, ip_map, mac_map)
    File.open(reportfile, 'w') {|f| f.write(JSON.pretty_generate(rpt)) }
    if entriesfile
      File.open(entriesfile, 'w') {|f| f.write(JSON.pretty_generate(entries)) }
    end
    if ipmap_output
      File.open(ipmap_output, 'w') {|f| f.write(JSON.pretty_generate(ip_map)) }
    end
  end
end

#### Main method
DIR = '~/netgear/'
puts "DEBUG: testing begins in #{DIR}"
logfile =       '#{DIR}netgear-routerlog-201809.txt'
entriesfile =   '#{DIR}netgear-routerlog-201809-entries.json'
reportfile =    '#{DIR}netgear-routerlog-201809-report.json'
macmap_input =  '#{DIR}netgearlogs-macmap.json'
ipmap_input =   '#{DIR}netgearlogs-ipmapin.json'
ipmap_output =  '#{DIR}netgear-routerlog-ipmapout-201809.json'
NetgearLogs.analyze_logfile(logfile: logfile, ipmap_input: ipmap_input, macmap_input: macmap_input, entriesfile: entriesfile, reportfile: reportfile, ipmap_output: ipmap_output)
puts "DEBUG: testing done!"
