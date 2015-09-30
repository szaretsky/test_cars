require 'socket'

1.times{ Kernel.fork }

n=1000
clients = {}
ts = Time.now
reqs = 0

while n>0
  n=n-1
  sock = TCPSocket.new( 'localhost', 2202 )
  clients[ sock ] =Fiber.new do |socket|
    loop do
      begin
        st = Time.now
        socket.write_nonblock("#{n}\n")
        s = socket.read_nonblock( n.to_s.length+2 )
        if s.chomp == n.to_s
          reqs+=1
          if( Time.now - ts > 1 )
            p "RPS #{(reqs/(Time.now-ts))}"
            ts = Time.now
            reqs = 0
          end
        end
      rescue
        Fiber.yield
        retry
      end
    end
  end
end

loop do
  clients.each {|sock,fib| fib.resume(sock) }
end
