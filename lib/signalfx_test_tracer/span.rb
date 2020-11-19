# frozen_string_literal: true

class OpenTracingTestTracer
  class Span
    attr_accessor :operation_name

    # NOTE: These are not OT compliant. These are meant only for testing.
    attr_reader :context, :start_time, :tags, :logs, :references, :end_time

    def initialize(
      context:,
      operation_name:,
      start_time: Time.now,
      tags: {},
      references: nil
    )
      @context = context
      @operation_name = operation_name
      @start_time = start_time
      @tags = tags
      @logs = []
      @references = references
    end

    # Set a tag value on this span
    #
    # @param key [String] the key of the tag
    # @param value [String, Numeric, Boolean] the value of the tag. If it's not
    # a String, Numeric, or Boolean it will be encoded with to_s
    def set_tag(key, value)
      sanitized_value = valid_tag_value?(value) ? value : value.to_s
      @tags = @tags.merge(key.to_s => sanitized_value)
    end

    # Set a baggage item on the span
    #
    # @param key [String] the key of the baggage item
    # @param value [String] the value of the baggage item
    def set_baggage_item(_key, _value)
      self
    end

    # Get a baggage item
    #
    # @param key [String] the key of the baggage item
    #
    # @return Value of the baggage item
    def get_baggage_item(_key)
      nil
    end

    # Add a log entry to this span
    #
    # @deprecated Use {#log_kv} instead.
    def log(*args)
      warn 'Span#log is deprecated. Please use Span#log_kv instead.'
      log_kv(*args)
    end

    # Add a log entry to this span
    #
    # @param timestamp [Time] time of the log
    # @param fields [Hash] Additional information to log
    def log_kv(timestamp: Time.now, **fields)
      @logs << fields.merge(timestamp: timestamp)
      nil
    end

    # Finish the {Span}
    #
    # @param end_time [Time] custom end time, if not now
    def finish(end_time: Time.now)
      @end_time = end_time
    end

    def to_s
      "Span(operation_name=#{@operation_name}, " \
        "tags=#{@tags}, " \
        "logs=#{@logs}, " \
        "start_time=#{@start_time}, " \
        "end_time=#{@end_time}, " \
        "context=#{@context})"
    end

    # NOTE: This is not OT compliant. This is meant only for testing.
    def finished?
      @end_time != nil
    end

    private

    def valid_tag_value?(value)
      value.is_a?(String) ||
        value.is_a?(Numeric) ||
        value.is_a?(TrueClass) ||
        value.is_a?(FalseClass)
    end
  end
end
