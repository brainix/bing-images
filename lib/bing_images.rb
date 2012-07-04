#!/usr/bin/env ruby

#-----------------------------------------------------------------------------#
#   bing_images.rb                                                            #
#                                                                             #
#   Copyright (c) 2012, Rajiv Bakulesh Shah, original author.                 #
#                                                                             #
#       This file is free software; you can redistribute it and/or modify     #
#       it under the terms of the GNU General Public License as published     #
#       by the Free Software Foundation, either version 3 of the License,     #
#       or (at your option) any later version.                                #
#                                                                             #
#       This file is distributed in the hope that it will be useful, but      #
#       WITHOUT ANY WARRANTY; without even the implied warranty of            #
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     #
#       General Public License for more details.                              #
#                                                                             #
#       You should have received a copy of the GNU General Public License     #
#       along with this file.  If not, see:                                   #
#           <http://www.gnu.org/licenses/>.                                   #
#-----------------------------------------------------------------------------#


require 'addressable/uri'
require 'net/http'
require 'net/https'
require 'rexml/document'
require 'URI'


module BingImages
  ACCOUNT_KEY = ENV['BING_ACCOUNT_KEY']
  URL = 'https://api.datamarket.azure.com/Bing/Search/Image'

  NUM_PAGES = 20
  RESULTS_PER_PAGE = 50

  def self.search(query, safe, offset)
    query = build_query(query, safe, offset)
    url = URL + '?' + query
    xml = issue_request(url)
    results = parse_xml(xml)
    results
  end

  def self.build_query(query, safe, offset)
    uri = Addressable::URI.new
    uri.query_values = {
      Query: "'" + query + "'",
      Adult: "'" + (safe ? 'Moderate' : 'Off') + "'",
      '$skip' => offset,
    }
    uri.query
  end

  def self.issue_request(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    query = uri.query.nil? ? '' : ('?' + uri.query)
    request = Net::HTTP::Get.new(uri.path + query)
    request.basic_auth('', ACCOUNT_KEY)
    response = http.request(request)
    response.body
  end

  def self.parse_xml(xml)
    doc = REXML::Document.new(xml)
    results = []
    doc.elements.each('feed/entry/content/m:properties') do |element|
      result = {
        thumbnail: (element.elements.each('d:Thumbnail/d:MediaUrl') {})[0].get_text,
        full_size: (element.elements.each('d:MediaUrl') {})[0].get_text,
      }
      results << result
    end
    results
  end
end


if __FILE__ == $0
  query = ARGV.join(' ')
  photos = BingImages.search(query, false, 0)
  puts photos
end
