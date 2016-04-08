require 'interactor'

module Interactors
  # Anonymous interactors
  # Does two things:
  #  - passes context to the proc
  #  - honors #compose interface
  class Anonymous
    include Interactor
    attr_reader :block

    def initialize(&blk)
      @block = blk
    end

    def call(context = {})
      block.call(context)
    end
  end
end
