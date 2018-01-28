#!/usr/bin/env ruby
require_relative 'library'
DESCRIPTION = <<HEREDOC
script.rb: exemplar of scoping between files.
HEREDOC

SCOPE_SCRIPT_CAPS = "SCOPE_SCRIPT_CAPS"
@scope_script_at = "scope_script_at"
scope_script_var = "scope_script_var"

puts "#{__FILE__} #{DESCRIPTION}"
puts "Debug1:script.rb:#{SCOPE_LIBRARY_CAPS}:#{@scope_library_at}::#{$scope_global_dollar}:l" # {scope_library_var}:" # gives error: undefined local variable or method `scope_library_var' for main:Object (NameError)
$scope_global_dollar = "scope_global_dollar-script"
puts "Debug2:script.rb:#{SCOPE_SCRIPT_CAPS}:#{@scope_script_at}:#{scope_script_var}:#{$scope_global_dollar}:l"
puts "ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"

# computer:path$ ./script.rb
# ~/canoniculled.com/ruby/library.rb library.rb: exemplar of scoping between files.
# Debug1:library.rb:SCOPE_LIBRARY_CAPS:scope_library_at:scope_library_var::s
# Debugs:library.rb:SCOPE_LIBRARY_CAPS:scope_library_at:scope_library_var:scope_global_dollar-library:s
# ./script.rb:3: warning: already initialized constant DESCRIPTION
# ~/canoniculled.com/ruby/library.rb:2: warning: previous definition of DESCRIPTION was here
# ./script.rb script.rb: exemplar of scoping between files.
# Debug1:script.rb:SCOPE_LIBRARY_CAPS:scope_library_at::scope_global_dollar-library:l
# Debug2:script.rb:SCOPE_SCRIPT_CAPS:scope_script_at:scope_script_var:scope_global_dollar-script:l
# ruby 2.4.1p111
