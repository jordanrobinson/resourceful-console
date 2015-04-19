#!/usr/bin/ruby
require 'net/http'
require 'net/https'
require 'net/smtp'
require 'json'
require 'rubygems'
require 'rest-client'

details = File.read('resourceguru.inf')

lines = details.split("\n")
username = lines[0].split('=')[1]
password = lines[1].split('=')[1]
mailgun_acc = lines[2].split('=')[1]
mailgun_key = lines[3].split('=')[1]

users = lines[4].split(',')

users.each { |user|

  uri = URI.parse('https://api.resourceguruapp.com/v1/buildingblocks/resources/' + user + '/')
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
  email = parsed_json['email']

  filepath = user + '-lastupdated.inf'

  if File.file?(filepath)
    last_update = File.read(filepath)
  else
    File.write(filepath, updated)
    last_update = updated
  end

  unless updated.eql?(last_update)
    File.write(filepath, updated)
    RestClient.post "https://api:key-" + mailgun_key + "@api.mailgun.net/v3/" + mailgun_acc + ".mailgun.org/messages",
                    :from => "Resourceful <postmaster@" + mailgun_acc + ".mailgun.org>",
                    :to => name + "<" + email + ">",
                    :subject => "Resource Guru has updated",
                    :text => name + ", Resource guru has changed!\nprevious:\t" + last_update + "\nnew:\t\t" + updated

    puts 'sending email to ' + name + ' for ' + updated
  end
  puts 'ran at ' + Time.now.getutc.to_s + ' for ' + email
}