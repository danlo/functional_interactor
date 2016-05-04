require 'functional_interactor'

module Interactors
  autoload :Sequence,  'interactors/sequence'
  autoload :Anonymous, 'interactors/anonymous'
  autoload :Simple,    'interactors/simple'

  # Helper
  def self.new(&blk)
    Interactors::Anonymous.new(&blk)
  end
end
