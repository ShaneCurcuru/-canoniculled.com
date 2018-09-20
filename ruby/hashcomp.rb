#!/usr/bin/env ruby
# Compare two hashes from files
require 'json'

# Return a string of raw HTML for a single dt/dl entry
def emit_definition(entry)
  val = '<dt>'
  val += "term"
  val += "</dt>\n  <dd>"
  val += "definition = #{entry}"
  val += "\n  (<a href=\""
  val += "url"
  val += "\">docs</a>)\n  </dd>"
  return val
end

# Return a string suitable for using as www/public/README.html
def emit_readme()
  val = "<h2>Public JSON files</h2><dl>\n"
  %w(one two).each do |entry|
    val += emit_definition(entry)
    val += "\n"
  end
  val += '</dl>'
  val += '<br/>For more information <a href="https://whimsy.apache.org/docs/">see the API documentation</a>'
  return val
end

puts "TEST"
puts emit_readme()
puts "Done"
exit 1



a = ARGV.shift
b = ARGV.shift

ha = JSON.parse(File.read(a))
hb = JSON.parse(File.read(b))
puts "TYPE,proj,check,val"
ha.each do |k, v|
  if hb.has_key?(k)
    v.each do |key, val|
      if hb[k].has_key?(key)
        if hb[k][key] == val
          # no-op
        else
          puts "DVAL,#{k},#{key},#{hb[k][key]},#{val}"
        end
      else
        puts "DIFF,#{k},#{key},missing key, #{val}"
      end
    end
  else
    puts "NOKEY,#{k},,no key at all"
  end
end


