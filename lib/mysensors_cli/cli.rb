require 'thor'
require 'serialport'

require 'byebug'

module MysensorsCli
  class Cli < Thor
    desc "connect dev baudrate", "Run cli"
    def connect(dev, baudrate)

      serialport = init_serial(dev, baudrate.to_i)
      mutex = Mutex.new


      threads = [
	 Thread.new { read_serial(serialport, mutex) },
         Thread.new { read_input(serialport, mutex) } ]
      
      threads.map(&:join)

      serialport.close
    end

    private
    def init_serial(port_str, baudrate)
      data_bits = 8
      stop_bits = 1
      parity = SerialPort::NONE

      SerialPort.new(port_str, baudrate, data_bits, stop_bits, parity)
    end

    def read_serial(serialport, mutex)
     while true do
       while (i = serialport.gets.chomp) do       # see note 2
        mutex.synchronize do
           puts i
        end
       end
     end
    end

    def read_input(serialport, mutex)
      while line = STDIN.gets.chomp do
        break if line === "exit;"
        mutex.synchronize do
          serialport.puts build_message(line)
        end
      end
      puts "exiting"
    end

    def build_message(message)
      node_id, subtype, payload = message.split(';')
      "#{node_id};0;1;0;#{subtype};#{payload}"
    end
  end
end
