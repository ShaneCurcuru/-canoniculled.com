#!/usr/bin/env ruby
DESCRIPTION = <<HEREDOC
library.rb: exemplar of scoping between files.
HEREDOC

SCOPE_LIBRARY_CAPS = "SCOPE_LIBRARY_CAPS"
@scope_library_at = "scope_library_at"
scope_library_var = "scope_library_var"

puts "#{__FILE__} #{DESCRIPTION}"
puts "Debug1:library.rb:#{SCOPE_LIBRARY_CAPS}:#{@scope_library_at}:#{scope_library_var}:#{$scope_global_dollar}:s"
$scope_global_dollar = "scope_global_dollar-library"
puts "Debugs:library.rb:#{SCOPE_LIBRARY_CAPS}:#{@scope_library_at}:#{scope_library_var}:#{$scope_global_dollar}:s"
