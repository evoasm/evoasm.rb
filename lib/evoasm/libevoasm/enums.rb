require 'ffi'

module Evoasm
  module Libevoasm
    enum :metric, [
      :absdiff, 0,
      :hamming, 1,
      :none
    ]


  end
end
