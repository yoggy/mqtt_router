mqtt_router.rb
====
simple mqtt message routing program.

Usage
----
    
    $ gem install mqtt
    $ git clone https://github.com/yoggy/mqtt_router.git
    $ cd mqtt_router
    $ cp mqtt_router_config.yaml.sample mqtt_router_config.yaml
    $ vi mqtt_router_config.yaml
    
        mqtt_host:     mqtt.example.com
        mqtt_port:     1883
        mqtt_username: username
        mqtt_password: password
    
    $ ./mqtt_router office_co2 7seg0003 'co2\":(.+),' 'segd#{sprintf("%04d",md[1].to_i)}'
    
Dataflow
----
![img01.png](img01.png)

Copyright and license
----
Copyright (c) 2016 yoggy

Released under the [MIT license](LICENSE.txt)
