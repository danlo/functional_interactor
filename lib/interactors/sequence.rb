require 'interactor'

module Interactors
  # An Interactor that is a sequence of Interactors
  class Sequence
    include Interactor
    include Kase

    def interactions
      @__interactions ||= []
    end

    def compose(interactor)
      interactions << interactor
      self
    end

    def call(context = {})
      interactions.inject(context, &method(:handle_response))
    end

    # Overrideable
    # The idea here is we can customize the flow control
    # for the sequence. Generally, we're looking for a
    # broadly applicable pattern. Some patterns are rare or
    # not orthogonal, and it is better to write a custom
    # class for it.
    def handle_response(context, interactor)
      kase interactor.call(context) do
        on(:ok)    { |context| context }
        on(:error) { |reason| return [:error, reason] }
      end
    end
  end
end
