module Interactors
  # An Interactor that is a sequence of Interactors
  class Sequence
    include Interactor

    def interactions
      @__interactions ||= []
    end

    def compose(interactor)
      interactions << interactor
      self
    end

    def call
      interactions.each do |interactor|
        interactor.call!(context)
        break if context.fail? # Stop the chain if any interaction fail
      end
    end
  end
end
