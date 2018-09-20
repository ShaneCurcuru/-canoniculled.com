#!/usr/bin/ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'


selectorYouTube = '#playlist'
urlYouTube = "http://www.youtube.com/watch?v=icvtIK83I_g&list=PLvsKqlNNP3R8HHU4HyOFoeioCtykKQQfC"


inputURL = "http://redmonk.com/?series=monktoberfest-2016"
selector = '#mainContent > div.row.block.block-grid.-archives > ul > li > a'

#doc = Nokogiri::HTML(open(inputURL))
#entries = doc.css(selector)

doc = Nokogiri::HTML(open("youtubepage.html"))
puts 
entries = doc.css('ytd-playlist-panel-video-renderer')

puts "debug "
puts entries.inspect



# puts entry[0].text
# puts entry[0].href

# reader = Nokogiri::HTML::Reader(open(inputURL))
# elm = []
# reader.each do |node|
#   next if node.node_type != Nokogiri::XML::Reader::TYPE_ELEMENT
#   next if node.name != 'a'
#   elm << node.inner_xml
# end
