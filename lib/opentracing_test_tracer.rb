# frozen_string_literal: true

require 'opentracing'
require 'logger'

require_relative 'opentracing_test_tracer/span'
require_relative 'opentracing_test_tracer/span_context'
require_relative 'opentracing_test_tracer/trace_id'
require_relative 'opentracing_test_tracer/scope_manager'
require_relative 'opentracing_test_tracer/scope'

class OpenTracingTestTracer
  def self.build(logger: Logger.new(STDOUT))
    new(logger: logger)
  end

  def initialize(logger:)
    @logger = logger
    @scope_manager = ScopeManager.new
    @spans = []
    @finished_spans = []
  end

  # NOTE: This is not OT compliant. This is meant only for testing.
  attr_reader :spans

  # @return [ScopeManager] the current ScopeManager, which may be a no-op but
  #   may not be nil.
  attr_reader :scope_manager

  # @return [Span, nil] the active span. This is a shorthand for
  #   `scope_manager.active.span`, and nil will be returned if
  #   Scope#active is nil.
  def active_span
    scope = scope_manager.active
    scope&.span
  end

  # Starts a new span
  #
  # This is similar to #start_active_span, but the returned Span will not be
  # registered via the ScopeManager.
  #
  # @param operation_name [String] The operation name for the Span
  # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
  #   the newly-started Span. If a Span instance is provided, its
  #   context is automatically substituted. See [Reference] for more
  #   information.
  #
  #   If specified, the `references` parameter must be omitted.
  # @param references [Array<Reference>] An array of reference
  #   objects that identify one or more parent SpanContexts.<Paste>
  # @param start_time [Time] When the Span started, if not now
  # @param tags [Hash] Tags to assign to the Span at start time
  # @param ignore_active_scope [Boolean] whether to create an implicit
  #   References#CHILD_OF reference to the ScopeManager#active.
  #
  # @return [Span] The newly-started Span
  def start_span(operation_name,
                 child_of: nil,
                 start_time: Time.now,
                 tags: nil,
                 references: nil,
                 ignore_active_scope: false,
                 **)
    context = prepare_span_context(
      child_of: child_of,
      references: references,
      ignore_active_scope: ignore_active_scope
    )
    span = Span.new(
      context: context,
      operation_name: operation_name,
      start_time: start_time,
      references: references,
      tags: tags
    )
    @spans << span
    span
  end

  # Creates a newly started and activated Scope
  #
  # If the Tracer's ScopeManager#active is not nil, no explicit references
  # are provided, and `ignore_active_scope` is false, then an inferred
  # References#CHILD_OF reference is created to the ScopeManager#active's
  # SpanContext when start_active is invoked.
  #
  # @param operation_name [String] The operation name for the Span
  # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
  #   the newly-started Span. If a Span instance is provided, its
  #   context is automatically substituted. See [Reference] for more
  #   information.
  #
  #   If specified, the `references` parameter must be omitted.
  # @param references [Array<Reference>] An array of reference
  #   objects that identify one or more parent SpanContexts.
  # @param start_time [Time] When the Span started, if not now
  # @param tags [Hash] Tags to assign to the Span at start time
  # @param ignore_active_scope [Boolean] whether to create an implicit
  #   References#CHILD_OF reference to the ScopeManager#active.
  # @param finish_on_close [Boolean] whether span should automatically be
  #   finished when Scope#close is called
  # @yield [Scope] If an optional block is passed to start_active it will
  #   yield the newly-started Scope. If `finish_on_close` is true then the
  #   Span will be finished automatically after the block is executed.
  # @return [Scope] The newly-started and activated Scope
  def start_active_span(operation_name,
                        child_of: nil,
                        references: nil,
                        start_time: Time.now,
                        tags: nil,
                        ignore_active_scope: false,
                        finish_on_close: true,
                        **)
    span = start_span(
      operation_name,
      child_of: child_of,
      references: references,
      start_time: start_time,
      tags: tags,
      ignore_active_scope: ignore_active_scope
    )
    scope = @scope_manager.activate(span, finish_on_close: finish_on_close)

    if block_given?
      begin
        yield scope
      ensure
        scope.close
      end
    end

    scope
  end

  # Inject a SpanContext into the given carrier
  #
  # @param span_context [SpanContext]
  # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
  # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
  def inject(span_context, format, carrier)
    case format
    when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_RACK
      carrier['test-traceid'] = span_context.trace_id
      carrier['test-parentspanid'] = span_context.parent_id
      carrier['test-spanid'] = span_context.span_id
    else
      @logger.error "#{format} format is not supported yet"
    end
  end

  # Extract a SpanContext in the given format from the given carrier.
  #
  # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
  # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
  # @return [SpanContext] the extracted SpanContext or nil if none could be found
  def extract(format, carrier)
    case format
    when OpenTracing::FORMAT_TEXT_MAP
      trace_id = carrier['test-traceid']
      parent_id = carrier['test-parentspanid']
      span_id = carrier['test-spanid']

      create_span_context(trace_id, span_id, parent_id)
    when OpenTracing::FORMAT_RACK
      trace_id = carrier['HTTP_TEST_TRACEID']
      parent_id = carrier['HTTP_TEST_PARENTSPANID']
      span_id = carrier['HTTP_TEST_SPANID']

      create_span_context(trace_id, span_id, parent_id)
    else
      @logger.error "#{format} format is not supported yet"
      nil
    end
  end

  private

  def create_span_context(trace_id, span_id, parent_id)
    return nil if !trace_id || !span_id

    SpanContext.new(
      trace_id: trace_id,
      parent_id: parent_id,
      span_id: span_id
    )
  end

  def prepare_span_context(child_of:, references:, ignore_active_scope:)
    parent_context =
      context_from_child_of(child_of) ||
      context_from_references(references) ||
      context_from_active_scope(ignore_active_scope)

    if parent_context
      SpanContext.create_from_parent_context(parent_context)
    else
      SpanContext.create_parent_context
    end
  end

  def context_from_child_of(child_of)
    return nil unless child_of
    child_of.respond_to?(:context) ? child_of.context : child_of
  end

  def context_from_references(references)
    return nil if !references || references.none?

    # Prefer CHILD_OF reference if present
    ref = references.detect do |reference|
      reference.type == OpenTracing::Reference::CHILD_OF
    end
    (ref || references[0]).context
  end

  def context_from_active_scope(ignore_active_scope)
    return if ignore_active_scope

    active_scope = @scope_manager.active
    active_scope&.span&.context
  end
end
