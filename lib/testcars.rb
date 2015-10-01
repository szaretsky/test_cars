require "testcars/version"
require 'eventmachine'
require 'testcars/carsinfo'
require 'testcars/messages'
require 'logger'
require 'em-http-server'
require 'json'


module Testcars
  
  # server handler for server-server connection
  class CarServerConnClient < EM::Connection
    attr_accessor :response, :status
    def receive_data( data )
      data.sub!(/\n$/,'')
      @response.content = JSON.generate( MessagePack.unpack( data ))
      @response.send_response
      HTTPJsonCarServer.release(self) 
    end
  end
     
  # server handler for http json server 
  class HTTPJsonCarServer < EM::HttpServer::Server

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::INFO

    @@connections = []

    # initial connection pool to eta server creation
    def self.connect( host, port, connections )
      connections.times do
        newconn = EM.connect( host, port,  CarServerConnClient )
        @@connections << newconn 
      end
    end

    def self.release( conn )
      @@connections.push( conn )
    end

    # look up for free connection
    def getetaserverconn
      return @@connections.pop
    end

    def process_http_request
      request = JSON.parse(@http_content)
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'
      conn = getetaserverconn
      if conn
        conn.response = response
        conn.send_data(MessageTransport.pack( { 'cmd' => 'eta', 'lat' => request['lat'], 'lon' => request['lon'] }) + "\n" ) 
      end
    end

    def http_request_errback e
      # printing the whole exception
      puts e.inspect
    end
  end


  # eta server handler
  class CarServer < EM::Connection

    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::INFO
    @@connections = 0

    def post_init
      @@connections+=1
      @buffer = ''
      @@logger.debug("Server intialized")
    end

    def receive_data( data )
      @buffer << data
      ( messages, @buffer ) = MessageTransport.extract( @buffer ) 
      fullmessage = messages.map{ |msg| MessageTransport.pack( process(msg)) }.join("\n")+"\n"
      send_data fullmessage
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
      # commands whitelist
      @@logger.debug("Receive command #{msg}")
      st = Time.now;
      result = nil
      case
      when msg['cmd'] == 'stats'
        result = { 'connections' => @@connections }
      when msg['cmd'] == 'eta'
        eta = CarsInfo.eta( msg['lat'], msg['lon'] )
        @@logger.debug("ETA #{eta}")
        result = { 'eta' => eta }
      when msg['cmd'] == 'add_random'
        CarsInfo.addrandomcars( msg['lat0'], msg['lon0'], msg['lat1'], msg['lon1'], 1000 )
      end  
      @@logger.debug("Processingtime #{Time.now - st}")
      result
    end

  end
  
  def Testcars.etaserver( cfg )
    EM.set_descriptor_table_size( 11000 )
    EM.epoll
    CarsInfo.connect cfg[:dbname], cfg[:user]
    EM.run {
      reload_data = lambda { EM.add_timer(1) { CarsInfo.load( reload_data ) }}
      CarsInfo.load( reload_data )
      EM.start_server cfg[:host] ? cfg[:host] : 'localhost' , cfg[:port] ? cfg[:port] : 2202, CarServer
    }
  end

  def Testcars.jsonserver( cfg )
    EM.set_descriptor_table_size( 11000 )
    EM.epoll
    EM.run {
      HTTPJsonCarServer.connect( cfg[:etahost] ? cfg[:etahost] : 'localhost', cfg[:etaport] ? cfg[:etaport] : 2202, 10000)
      EM::start_server(cfg[:host] ? cfg[:host] : 'localhost' , cfg[:port] ? cfg[:port] : 8081, HTTPJsonCarServer)
    }
  end
    

end
