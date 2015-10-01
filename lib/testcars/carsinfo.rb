require 'pg/em'
require 'haversine'
require 'testcars/version'

class CarsInfo
  @cars = []
  @status = :not_loaded
  @pgconn = nil
  class << self
    attr_accessor :pgconn

    def connect( dbname, user )
      @pgconn = PG::EM::Client.new dbname: dbname, user: user
    end

    # synchronious cars data loading
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

    # getting ETA
    def eta(lat,long)
      if @status == :loaded
        dists = []
        tst = Time.now
        dists = @cars.map {|car| Haversine.distance( lat.to_f, long.to_f, car[0].to_f, car[1].to_f ) * 1.5 }
#p "calc time #{(Time.now - tst)}"
        tst = Time.now
        dists.sort[0,3].inject(0) {|s,i| s+=i }/3
#p "sort time #{(Time.now - tst)}"
      else
        nil
      end
    end

    # method for test car generation
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

