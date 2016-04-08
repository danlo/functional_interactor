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

    alias_method :|, :compose

    def call(context = {})
      interactions.inject(context) do |context, interactor|
        kase interactor.call(context) do
          on(:ok)    { |context| context }
          on(:error) { |reason| return [:error, reason] }
        end
      end
    end
  end
end
