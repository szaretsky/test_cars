require 'socket'
require 'epoll'

class CarsMServer
  def initialize( host, port )
    @host = host
    @port = port
    @clients = {}
    @dbconnpool = [] # database connections pool
    @server = TCPServer.new( host, port )
    @ep = Epoll.create
    @ep.add @server, Epoll::IN
  end

  def evloop
    loop do
      @ep.wait.each do |ev|
        data = ev.data
        events = ev.events

        if data == @server
          socket = @server.accept
          @ep.add socket, Epoll::IN|Epoll::ET
        elsif (events & Epoll::IN) != 0
          data.recv(1024)
          @ep.mod data, Epoll::OUT|Epoll::ET
        elsif (events & Epoll::OUT) != 0
          data.puts response
          @ep.del data
          data.close
        elsif (events & (Epoll::HUP|Epoll::ERR)) != 0
          p "Epoll::HUP|Epoll::ERR"
        else
          raise IOError
        end
      end
    end
  end

  def mainloop
    loop do
      (read_processing, write_processing) = IO.select( @clients.keys << @server, nil )
      read_processing.each do |socket|
        if socket == @server # new client
          client = @server.accept_nonblock
          @clients[ client ] = Fiber.new do |socket|
            loop do
              message = socket.gets
              if message.chomp == 'close'
                @clients.delete(socket)
                socket.close
                break
              end
              socket.puts( message )
              Fiber.yield
            end
          end
        else
          @clients[ socket ].resume( socket )
        end
      end
    end
  end

  def async_mainloop
    loop do 
      begin
        client = @server.accept_nonblock
        @clients[ client ] = Fiber.new do |socket|
          message = ''
          loop do
            begin
              message << socket.read_nonblock(1000)
              if message[-1] == "\n"
                socket.puts( message )
                if message.chomp == 'close'
                  @clients.delete(socket)
                  socket.close
                  break
                end
                message = ''
              end
            rescue EOFError
              socket.close
              @clients.delete(socket) 
              break
            rescue
              Fiber.yield
            end
          end
        end
        @clients.each{ |client,fib| fib.resume(client)}
        p "Clients #{@clients.length}"
      rescue
        @clients.each{ |client,fib| fib.resume(client)}
        sleep(0.00001)
      end
    end
  end 
end

srv = CarsMServer.new( 'localhost', 2202 )
#srv.async_mainloop
srv.evloop
#srv.mainloop
    
  
