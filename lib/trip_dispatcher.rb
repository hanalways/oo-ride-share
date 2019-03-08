require "csv"
require "time"

require_relative "passenger"
require_relative "trip"
require_relative "driver"

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize(directory: "./support")
      @passengers = Passenger.load_all(directory: directory)
      @trips = Trip.load_all(directory: directory)
      @drivers = Driver.load_all(directory: directory)
      connect_trips
    end

    def find_passenger(id)
      Passenger.validate_id(id)
      return @passengers.find { |passenger| passenger.id == id }
    end

    def find_driver(id)
      Driver.validate_id(id)
      return @drivers.find { |driver| driver.id == id }
    end

    def request_trip(passenger_id)
      avail_driver = @drivers.select do |driver|
        puts "#{driver.id} #{driver.status}"
        driver.status == :AVAILABLE
      end.first

      if avail_driver == nil
        raise ArgumentError, "no available drivers"
      end

      passenger = find_passenger(passenger_id)

      trip_info = {
        id: @trips.last.id + 1,
        passenger: passenger,
        start_time: Time.now.to_s,
        end_time: nil,
        cost: nil,
        rating: nil,
        driver: avail_driver,
      }

      trip = RideShare::Trip.new(trip_info)

      @trips << trip

      avail_driver.add_trip(trip)
      passenger.add_trip(trip)
      avail_driver.change_status(trip)

      return trip
    end

    def inspect
      # Make puts output more useful
      return "#<#{self.class.name}:0x#{object_id.to_s(16)} \
              #{trips.count} trips, \
              #{drivers.count} drivers, \
              #{passengers.count} passengers>"
    end

    private

    def connect_trips
      @trips.each do |trip|
        passenger = find_passenger(trip.passenger_id)
        driver = find_driver(trip.driver_id)
        trip.connect(passenger, driver)
      end

      return trips
    end
  end
end
