$LOAD_PATH.unshift('lib/')
require 'testcars'

######################################################################
#
#  Timy http server to work with etaserver
#   Responds to JSON { "cmd": "eta", "lat" : "55", "lon" : "34.123" }
#
#######################################################################

# params: host and port for http server, etahost, etaport - host and port for eta service
Testcars.jsonserver( host: 'localhost', port: 8081  )
