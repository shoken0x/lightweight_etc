#!/usr/bin/env ruby
 
require 'rubygems'
require 'yaml'
require 'aws-sdk'
 
config = YAML.load(File.read("/etc/aws.yml"))
AWS.config(config)
 
ec2 = AWS::EC2.new
 
ec2.instances.each do |instance|
  if instance.vpc_id =~ /^vpc-.*$/
    instance.security_groups.each do |sg|
      sg.ip_permissions.each do |permission|
        permission.ip_ranges.each do |source|
          if source == "0.0.0.0/0"
            puts "(danger)"
            puts "Instance: #{instance.vpc_id}"
            puts "Protocol: #{permission.protocol}"
            puts "Source: #{source}"
            puts "Port_range: #{permission.port_range}"
          end
        end
      end
    end
  end
end
