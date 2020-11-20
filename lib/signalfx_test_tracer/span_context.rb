# frozen_string_literal: true

class OpenTracingTestTracer
  # SpanContext holds the data for a span that gets inherited to child spans
  class SpanContext
    def self.create_parent_context
      trace_id = TraceId.generate
      new(trace_id: trace_id, span_id: trace_id)
    end

    def self.create_from_parent_context(span_context)
      new(
        span_id: TraceId.generate,
        parent_id: span_context.span_id,
        trace_id: span_context.trace_id
      )
    end

    attr_reader :span_id, :parent_id, :parent_span_id, :trace_id, :baggage

    def initialize(span_id:, parent_id: nil, trace_id:, baggage: {})
      @span_id = span_id
      @parent_id = parent_id
      @parent_span_id = parent_id
      @trace_id = trace_id
      @baggage = baggage
    end

    def to_s
      "SpanContext(trace_id=#{@trace_id}, " \
        "span_id=#{@span_id}, " \
        "parent_id=#{@parent_id}, " \
        "baggage=#{@baggage})"
    end
  end
end
