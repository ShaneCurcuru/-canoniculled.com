#!/usr/bin/env ruby
DESCRIPTION = <<HEREDOC
args.rb: exemplar of passing arguments.
https://docs.ruby-lang.org/en/2.5.0/syntax/calling_methods_rdoc.html
Argument order: positional arguments; then keyword arguments (like {}); then a block

'If the method definition has a *argument extra positional arguments will be assigned to argument in the method as an Array.'
For positional args with some defaults, some without defaults, it fills in all the undefaulted ones first from caller in order.

'Any keyword arguments not given will use the default value from the method definition. If a keyword argument is given that the method did not list an ArgumentError will be raised.'
HEREDOC

def dump_star(*args)
  ctr = 0
  puts __method__
  args.each do |a|
    puts "#{ctr}: #{a}"
    ctr += 1
  end
end
def dump_starstar(**args)
  ctr = 0
  puts __method__
  args.each do |a|
    puts "#{ctr}: #{a}"
    ctr += 1
  end
end

a = [1, 2, 3]
puts "a = [1, 2, 3]"
puts "a is: #{a}"

b = [*a, 4, 5, 6]
puts "b = [*a, 4, 5, 6]"
puts "b is: #{b}"

c = {x: 7, y: 8, z: 9}
puts "c = {x: 7, y: 8, z: 9}"
puts "c is: #{c}"

d = {**c, u: -3, v: -2, w: -1}
puts "d = {**c, u: -3, v: -2, w: -1}"
puts "d is: #{d}"

puts "dump_star(*b) ----"
dump_star(*b) 
puts "dump_star(**d) ----"
dump_star(**d)
# puts "dump_starstar(*b) ----"
# dump_starstar(*b) 
# args.rb:21:in `dump_starstar': wrong number of arguments (given 6, expected 0) (ArgumentError)
puts "dump_starstar(**d) ----"
dump_starstar(**d) 