#!/usr/bin/ruby
# encoding: utf-8
require 'aws-sdk'

instancelist = [
                "i-71eaa772", #Nginx server
                "i-b3d796b0", #Node.js server
                "i-3f11683c", #MongoDB server
                "i-61dfa462", #client1 server
               ]

COMMAND=["start", "stop", "status"]

unless ARGV.size == 1
  puts "Usage: #{$0} <command(#{COMMAND.join('|')})>"
  puts ""
  exit 1
end

command = ARGV[0]

unless COMMAND.index(command)
  puts "command must be #{COMMAND.join(' or ')} !"
  puts ""
  exit 1
end
 
AWS.config(YAML.load(File.read("/etc/aws.yml")))
 

instancelist.each do |ins|
  i = AWS::EC2.new.instances[ins]
  if command == 'start' && i.status == :stopped
    puts "start #{i.tags['Name']}"
    i.start
  elsif command == 'stop' && i.status == :running
    puts "stop #{i.tags['Name']}"
    i.stop
  elsif command == 'status'
    puts "#{i.tags['Name']} is #{i.status}"
  end
end
 
