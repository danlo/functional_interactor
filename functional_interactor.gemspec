# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name    = "functional_interactor"
  spec.version = "0.0.1"

  spec.author      = "Ho-Sheng Hsiao"
  spec.email       = "hosh@legal.io"
  spec.description = "Functional Interactor using Kase protocol and composition operators"
  spec.summary     = "Functional Interactor, composable, higher-order interactors. Complete rewrite of collectiveideas/interactor"
  spec.homepage    = "https://github.com/hosh/functional_interactor"
  spec.license     = "MIT"

  spec.files      = `git ls-files`.split($/)
  spec.test_files = spec.files.grep(/^spec/)

  spec.add_dependency 'activesupport', '~>4.2'
  #spec.add_dependency 'hosh-kase'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.3"
end
