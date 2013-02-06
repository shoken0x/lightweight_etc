#!/usr/bin/ruby
# encoding: utf-8
require 'aws-sdk'

NODE=["apache22", "apache24", "nginx", "node", "jboss", "mongo", "oracle", "client1", "gfc"]
instancelist = [
                "i-2393d020", #Apache2.2 server
                "i-8193d082", #Apache2.4 server
                "i-71eaa772", #Nginx server
                "i-b3d796b0", #Node.js server
                "i-13aed410", #JBoss server
                "i-3f11683c", #MongoDB server
                "i-11c0bb12", #Oracle server
                "i-61dfa462", #client1 server
                "i-45570a46" #GrowthForecast
               ]
nodehash = Hash.new
NODE.each_with_index do |n,i|
  nodehash[n] = instancelist[i]
end

COMMAND=["start", "stop", "status"]

unless ARGV.size == 2
  puts "Usage: #{$0} <{#{NODE.join('|')}}> <command(#{COMMAND.join('|')})>"
  puts ""
  exit 1
end

node = ARGV[0]
command = ARGV[1]

unless NODE.index(node)
  puts "node must be #{NODE.join(' or ')} !"
  puts ""
  exit 1
end

unless COMMAND.index(command)
  puts "command must be #{COMMAND.join(' or ')} !"
  puts ""
  exit 1
end
 
AWS.config(YAML.load(File.read("/etc/aws.yml")))
 

i = AWS::EC2.new.instances[nodehash[node]]
if command == 'start' && i.status == :stopped
  puts "start #{i.tags['Name']}"
  i.start
elsif command == 'stop' && i.status == :running
  puts "stop #{i.tags['Name']}"
  i.stop
elsif command == 'status'
  puts "#{i.tags['Name']} is #{i.status}"
end
 
