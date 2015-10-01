require 'msgpack'
require 'testcars/version'

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
