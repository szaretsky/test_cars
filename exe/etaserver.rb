$LOAD_PATH.unshift('lib/')
require 'testcars'

##################################
#
# ETA service.
#    Gets and responds by means of msgpacked hash 
# Req: { "cmd" => "eta", "lat" => ..., "lon" => ... }
# Resp:  { "eta" => ... }
#
##################################

# port for eta service

Testcars.etaserver( dbname: 'cars', user: 'devel', port: 2202  )
