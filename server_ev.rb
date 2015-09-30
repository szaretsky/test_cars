require 'eventmachine'
require 'msgpack'
require 'pg/em'
require 'haversine'

# Event machine 10k connections server

class CarsInfo
  @cars = []
  @status = :not_loaded
  @pgconn = nil
  class << self
    attr_accessor :pgconn
    def load( callback )
      Fiber.new do
        begin
          @pgconn.query('select * from cars') do |result|
            result.check
            @cars = []
            result.each_row do |row|
              @cars << row
            end
            @status = :loaded
          end
        rescue
          p $!
          @status = :not_loaded
        end
        callback.call
      end.resume
    end
    def eta(lat,long)
      if @status == :loaded
        dists = []
        ts = Time.now
        dists = @cars.map {|car| Haversine.distance( lat.to_f, long.to_f, car[0].to_f, car[1].to_f ) * 1.5 }
#p Time.now-ts
        ts = Time.now
        dists.sort[0,3].inject(0) {|s,i| s+=i }/3
#p Time.now-ts
      else
        nil
      end
    end
    # insert random cars in rectangle
    def addrandomcars(lat0,lon0,lat1,lon1, count )
      Fiber.new do
        count.times do
          lat = (lat1-lat0) * rand() + lat0
          lon = (lon1-lon0) * rand() + lon0
          @pgconn.query("insert into cars(lat,lon,avail) values(#{lat},#{lon}, true)")
        end
      end.resume
    end
  end  
end

class MessageTransport
  class << self
    # extract from binary
    def extract( data )
      messages = []
      while data.gsub!(/(^.*?)\n/,'') do
        messages << MessagePack.unpack( $1 )
      end
      return [ messages, data ]
    end

    # transform to binary
    def pack( message )
      message.to_msgpack 
    end

  end
end

  

# server handler
class CarServer < EM::Connection
  @@connections = 0

  def post_init
    @@connections+=1
    @buffer = ''
  end

  def receive_data( data )
    @buffer << data
    ( messages, @buffer ) = MessageTransport.extract( @buffer ) 
    send_data messages.map{ |msg| MessageTransport.pack( process(msg)) }.join("\n")+"\n"
  end

  def unbind
    @@connections-=1
  end

  # get stats
  def self.connections
    @@connections
  end

private

  def process(msg)
    case
    when msg['cmd'] == 'stats'
      { 'connections' => @@connections }
    when msg['cmd'] == 'eta'
      { 'eta' => CarsInfo.eta( msg['lat'], msg['lon'] ) }
    when msg['cmd'] == 'add_random'
      CarsInfo.addrandomcars( msg['lat0'], msg['lon0'], msg['lat1'], msg['lon1'], 1000 )
    end  
  end

end

# Note that this will block current thread.
EM.set_descriptor_table_size( 11000 )
EM.epoll
CarsInfo.pgconn = PG::EM::Client.new dbname: 'cars', user: 'devel'
p CarsInfo.pgconn
EM.run {
  reload_data = lambda { EM.add_timer(1) { CarsInfo.load( reload_data ) }}
  CarsInfo.load( reload_data )
#  db.connect( 'cars', 'devel' ).callback do |status|
#    if status 
#       CarsInfo.load    
#    else 
#      p "Error #{$!}"
#    end
#  end
#  EM
  EM.start_server "localhost", 2202, CarServer
}
