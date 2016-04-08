require 'interactor'

module Interactors
  autoload :Sequence,  'interactors/sequence'
  autoload :Anonymous, 'interactors/anonymous'

  # Helper
  def self.new(&blk)
    Interactors::Anonymous.new(&blk)
  end
end
