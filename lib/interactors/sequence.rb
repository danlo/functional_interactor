require 'interactor'

module Interactors
  # An Interactor that is a sequence of Interactors
  class Sequence
    include FunctionalInteractor
    include Kase

    def interactions
      @__interactions ||= []
    end

    def compose(interactor)
      interactions << interactor
      self
    end

    def call(context = {})
      interactions.each do |interactor|
        results = interactor.call(context)
        next if results[0] == :ok
        return results if results[0] == :error
        raise ArgumentError, "Return value from interactor must be [:ok, context] or [:error, ...]"
      end
      [:ok, context]
    end
  end
end
