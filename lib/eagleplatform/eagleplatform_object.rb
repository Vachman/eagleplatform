module Eagleplatform
  # @api private
  # Class provides methods for all Eagleplatform Objects
  class EagleplatformObject < Struct    
    # @return [Hash] convert Struct to Hash
    def to_hash
      Hash[self.each_pair.to_a]
    end
  end
end