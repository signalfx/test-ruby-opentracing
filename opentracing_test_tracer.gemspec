# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'signalfx_test_tracer'
  spec.version       = '0.1.4'
  spec.authors       = ['SignalFx Engineers']
  spec.email         = ['eng@signalfx.com']

  spec.summary       = 'SignalFx OpenTracing Tracer implementation for Tests in Ruby'
  spec.description   = ''
  spec.homepage      = 'https://github.com/signalfx/test-ruby-opentracing'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.54.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.24.0'

  spec.add_dependency 'opentracing'
end
