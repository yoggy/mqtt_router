#!/usr/bin/ruby
#
# mqtt_router.rb - Simple mqtt message routing program.
#
# Usage:
#   $ gem install mqtt
#   $ git clone https://github.com/yoggy/mqtt_router.git
#   $ cd mqtt_router
#   $ cp config.yaml.sample config.yaml
#   $ vi config.yaml
#   
#       mqtt_host:     mqtt.example.com
#       mqtt_port:     1883
#       mqtt_use_auth: false
#       mqtt_username: username
#       mqtt_password: password
#       mqtt_subscribe_topic: subscribe_topic
#       mqtt_subscribe_regex: co2\":(.+),
#       mqtt_publish_topic: publish_topic
#       mqtt_publish_format: segd#{sprintf("%04d",md[1].to_i)}
#
#   $ ./mqtt_router ./config.yaml
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

def usage
  puts <<-EOS
usage : #{$0} [configuration yaml file]

example :
   $ vi config.yaml
       mqtt_host:     mqtt.example.com
       mqtt_port:     1883
       mqtt_use_auth: false
       mqtt_username: username
       mqtt_password: password
       mqtt_subscribe_topic: subscribe_topic
       mqtt_subscribe_regex: co2\":(.+),
       mqtt_publish_topic: publish_topic
       mqtt_publish_format: segd\#{sprintf("%04d",md[1].to_i)}
   $ ./mqtt_router conf.yaml!

EOS
  exit(0)
end
usage if ARGV.size != 1

$conf = OpenStruct.new(YAML.load_file(ARGV[0]))

$regexp    = Regexp.new($conf.mqtt_subscribe_regexp)
$format    = $conf.mqtt_publish_format

def main
  conn_opts = {
    remote_host: $conf.mqtt_host
  }

  if $conf.mqtt_port > 0
    conn_opts["remote_port"] = $conf.mqtt_port
  end

  if $conf.mqtt_use_auth == true
    conn_opts["username"] = $conf.mqtt_username
    conn_opts["password"] = $conf.mqtt_password
  end

  $log.info "connecting..."
  MQTT::Client.connect(conn_opts) do |c|
    $log.info "connected"
    $log.info "subscribe topic=" + $conf.mqtt_subscribe_topic
    c.get($conf.mqtt_subscribe_topic) do |t, msg|
      $log.info "received message : msg=" + msg

      md = $regexp.match(msg)
      $log.debug "MatchData size=#{md.size}"
      md.size.times {|i|
        $log.debug "  md[#{i}] = #{md[i]}"
      }
      result = eval(%Q("#{$format}"))
      $log.debug "result=#{result}"

      $log.debug "publish : topic=#{$pub_topic}, msg=#{result}"
      c.publish($conf.mqtt_publish_topic, result)
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

