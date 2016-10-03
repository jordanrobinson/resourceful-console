#!/usr/bin/ruby
require 'net/http'
require 'net/https'
require 'net/smtp'
require 'json'
require 'rubygems'
require 'rest-client'
require 'openssl'

prefs = JSON.parse(File.read('prefs.json'))

username = prefs['username']
password = prefs['password']
mailgun_acc = prefs['mailgun_acc']
mailgun_key = prefs['mailgun_key']

users = prefs['accounts']

users.each { |user|

  url = 'https://api.resourceguruapp.com/v1/buildingblocks/resources/' + user + '/'
  res = RestClient::Request.execute method: :get, url: url, user: username, password: password, verify_ssl: false

  parsed_json = JSON.parse(res)

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

    today = Time.now.strftime('%F')

    url = 'https://api.resourceguruapp.com/v1/buildingblocks/reports/resources/' + user + '?start_date=' + today + '&end_date=2020-12-25'
    res = RestClient::Request.execute method: :get, url: url, user: username, password: password, verify_ssl: false

    parsed_json = JSON.parse(res)
    projects = parsed_json['projects']

    project_list = ''

    projects.each { |project|
      unless project['name'] == 'Bank Holiday' || project['name'] == 'Holiday'
        project_list += project['name'] + "\n"
      end
    }

    RestClient.post 'https://api:key-' + mailgun_key + '@api.mailgun.net/v3/' + mailgun_acc + '.mailgun.org/messages',
                    :from => 'Resourceful <postmaster@' + mailgun_acc + '.mailgun.org>',
                    :to => name + '<' + email + '>',
                    :subject => 'Resource Guru has updated',
                    :text => name + ", Resource guru has changed!\nprevious:\t" + last_update + "\nnew:\t\t" + updated + "\nCurrent projects:\n\n" + project_list

    puts 'sending email to ' + name + ' for ' + updated
  end
  puts 'ran at ' + Time.now.getutc.to_s + ' for ' + email
}
