######################################################
#
#  test http server. 10k connections at the same time
#
######################################################

require 'eventmachine'
require 'msgpack'
require 'em-http'

EM.set_descriptor_table_size( 11000 )
EM.epoll

rps = 0
ts = Time.now
url = 'http://localhost:8081/'

lat0 = 55.761081
lon0 = 37.36745
lat1 = 55.910224
lon1 = 37.84197

EM.run {
  req = lambda do
    lat = (lat1-lat0) * rand + lat0
    lon = (lon1-lon0) * rand + lon0
    http = EM::HttpRequest.new( url ).post :body => '{ "cmd" : "eta", "lat" : "'+lat.to_s+'", "lon" : "'+lon.to_s+'" }'
    http.callback {
      rps+=1
      if( Time.now-ts)>2
        p "RPS #{rps/(Time.now-ts)}"
        rps =0
        ts = Time.now
      end
      1.times{ req.call } #if currentreq < maxreq
    }
  end
  10000.times { req.call }
}
