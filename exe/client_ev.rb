######################################################
#
#  test eta server. 10k connections at the same time
#
######################################################

require 'eventmachine'
require 'msgpack'

class TestClient < EM::Connection
  @@ts = Time.now
  @@rps = 0
  def connection_completed
    @@rps+=1
    self.send_data( { 'cmd' => 'eta', 'lat' => 55.776062, 'lon' => 37.601596 }.to_msgpack+"\n" )
#    self.send_data( { 'cmd' => 'add_random', 'lat0' => 55.761081, 'lon0' => 37.36745, 'lat1' => 55.910224, 'lon1' => 37.84197 }.to_msgpack+"\n" )
  end

  def receive_data data
#    p MessagePack.unpack(data.chomp)
    @@rps+=1
    if( Time.now-@@ts)>10
      p "RPS #{@@rps/(Time.now-@@ts)}"
      @@rps =0
      @@ts = Time.now
    end
    self.send_data( { 'cmd' => 'eta', 'lat' => 55.776062, 'lon' => 37.601596 }.to_msgpack+"\n" )
#    sleep 0.1
#    self.send_data( { 'cmd' => 'stats'}.to_msgpack+"\n" )
  end

  def unbind
#    puts "A connection has terminated"
  end

end

EM.set_descriptor_table_size( 11000 )
p EM.set_descriptor_table_size
EM.epoll
EM.run {
  10000.times { EM.connect "localhost", 2202, TestClient }
}
