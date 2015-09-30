require 'socket'

class CarsMServer
  def initialize( host, port )
    @host = host
    @port = port
    @clients = {}
    @dbconnpool = [] # database connections pool
    @server = TCPServer.new( host, port )
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
srv.async_mainloop
#srv.mainloop
    
  
