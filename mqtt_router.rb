#!/usr/bin/ruby
#
# mqtt_router.rb - Simple mqtt message routing program.
#
# Usage:
#   $ gem install mqtt
#   $ git clone https://github.com/yoggy/mqtt_router.git
#   $ cd mqtt_router
#   $ cp mqtt_router_config.yaml.sample mqtt_router_config.yaml
#   $ vi mqtt_router_config.yaml
#   
#       mqtt_host:     mqtt.example.com
#       mqtt_port:     1883
#       mqtt_username: username
#       mqtt_password: password
#
#   $ ./mqtt_router office_co2 7seg0003 'co2\":(.+),' 'segd#{sprintf("%04d",md[1].to_i)}'
#
# License:
#   Copyright (c) 2016 yoggy <yoggy0@gmail.com>
#   Released under the MIT license
#   http://opensource.org/licenses/mit-license.php;
#
require 'mqtt'
require 'logger'
require 'fileutils'
require 'yaml'
require 'ostruct'

$stdout.sync = true
Dir.chdir(File.dirname($0))

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$conf = OpenStruct.new(YAML.load_file(File.dirname($0) + '/mqtt_router_config.yaml'))

def usage
  puts "usage : #{$_} sub_topic pub_topic regexp format"
  puts ""
  puts "    example"
  puts %q!        ./mqtt_router office_co2 7seg0003 'co2\":(.+),' 'segd#{sprintf("%04d",md[1].to_i)}'!
  puts ""
  puts ""
  exit(0)
end

usage if ARGV.size != 4

$sub_topic = ARGV[0]
$pub_topic = ARGV[1]
$regexp    = Regexp.new(ARGV[2])
$format    = ARGV[3]

def main
  conn_opts = {
    remote_host: $conf.mqtt_host,
    remote_port: $conf.mqtt_port,
    username:    $conf.mqtt_username,
    password:    $conf.mqtt_password,
  }

  $log.info "connecting..."
  MQTT::Client.connect(conn_opts) do |c|
    $log.info "connected"
    $log.info "subscribe topic=" + $sub_topic
    c.get($sub_topic) do |t, msg|
      $log.info "received message : msg=" + msg

      md = $regexp.match(msg)
      $log.debug "MatchData size=#{md.size}"
      md.size.times {|i|
        $log.debug "  md[#{i}] = #{md[i]}"
      }
      result = eval(%Q("#{$format}"))
      $log.debug "result=#{result}"

      $log.debug "publish : topic=#{$pub_topic}, msg=#{result}"
      c.publish($pub_topic, result)
    end
  end
end

if __FILE__ == $0
  loop do
    begin
      main
    rescue Exception => e
      exit(0) if e.class.to_s == "Interrupt"
      $log.error e
      $log.info "reconnect after 5 second..."
      sleep 5
    end
  end
end

