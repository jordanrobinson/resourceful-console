#!/usr/bin/ruby
require 'net/http'
require 'net/https'
require 'net/smtp'
require 'json'

details = File.read('resourceguru.inf')

lines = details.split("\n")
username = lines[0].split('=')[1]
password = lines[1].split('=')[1]

uri = URI.parse('https://api.resourceguruapp.com/v1/buildingblocks/resources/me/')
req = Net::HTTP::Get.new(uri.path)

req.basic_auth username, password

res = Net::HTTP.start(uri.host,
                      uri.port,
                      :use_ssl => uri.scheme == 'https') { |http|
  http.request(req)
}


parsed_json = JSON.parse(res.body)
name = parsed_json['name']
updated = parsed_json['updated_at'].gsub('T', ' ')

last_update = File.read('lastupdated.inf')

unless updated.eql?(last_update)
  File.write('lastupdated.inf', updated)
  puts name + " - Resource guru has changed!\nprevious:\t" + last_update + "\nnew:\t\t" + updated
end
