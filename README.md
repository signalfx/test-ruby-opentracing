# OpenTracingTestTracer

OpenTracing compatible in-memory Tracer implementation. It exposes information about the recorded spans which are useful for testing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'opentracing_test_tracer'
```

## Usage

```ruby
require 'opentracing_test_tracer'
OpenTracing.global_tracer = OpenTracingTestTracer.build

OpenTracing.start_active_span('span name') do
  # do something

  OpenTracing.start_active_span('inner span name') do
    # do something else
  end
end
```

See [opentracing-ruby](https://github.com/opentracing/opentracing-ruby) for more examples.

In addition to OpenTracing compatible methods this tracer provides following methods:

### OpenTracingTestTracer

1. `#spans` returns all spans, including those in progress.

### OpenTracingTestTracer::Span

1. `finished?` informs whether the span is finished.
2. `start_time` returns when the span was started.
3. `end_time` returns when the span was finished, or nil if still in progress.
4. `tags` returns the span tags.
5. `logs` returns the span logs.

### OpenTracingTestTracer::SpanContext

1. `trace_id` returns the trace ID.
1. `span_id` returns the current span ID.
2. `parent_id` returns the parent span ID.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salemove/test-ruby-opentracing

## Credits

This gem is heavily inspired by @iaintshine [test-tracer](https://github.com/iaintshine/ruby-test-tracer).

**opentracing_test_tracer** is maintained and funded by [SaleMove, Inc].

[SaleMove, Inc]: http://salemove.com/ "SaleMove Website"
