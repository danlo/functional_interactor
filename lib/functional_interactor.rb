require 'active_support/concern'
require 'interactors'

# Include this to support interactor interface
module FunctionalInteractor
  extend ActiveSupport::Concern

  included do
    attr_reader :context # Probably don't need this anymore, just pass it into #call
    alias_method :|, :compose
  end

  # | aliases to compose, so you can do something like:
  # (CreateOrder | ChargeCard.new(token: params[:token]) | SendThankYou).call
  def compose(interactor)
    Interactors::Sequence.new.compose(self).compose(interactor)
  end

  alias_method :|, :compose

  def call(context)
    [:ok, context]
  end

  class_methods do
    # | aliases to compose, so you can do something like:
    # (CreateOrder | ChargeCard.new(token: params[:token]) | SendThankYou).call
    def compose(interactor)
      Interactors::Sequence.new.compose(self).compose(interactor)
    end

    alias_method :|, :compose

    def call(context = {})
      new.call(context)
    end
  end
end
