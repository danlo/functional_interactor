require 'interactor'

module Interactors
  # Anonymous interactors
  # Does two things:
  #  - passes context to the proc
  #  - honors #compose interface
  #  - Only return [:error, ... ] if exception is raised
  #  - otherwise, always return [:ok, context]
  class Simple
    include Interactor
    attr_reader :block

    def initialize(&blk)
      @block = blk
    end

    def call(context = {})
      handle_error do
        block.call(context)
      end
    end

    # This is meant to be overridable. Maybe you
    # want to use something else, such as capturing
    # network errors, or wrap around specific third-party
    # libraries.
    def handle_error
      yield
      [:ok, context]
    rescue Exception => e
      [:error, e]
    end
  end
end
