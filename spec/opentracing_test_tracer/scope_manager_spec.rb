# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenTracingTestTracer::ScopeManager do
  let(:scope_manager) { described_class.new }
  let(:span) { instance_spy(OpenTracingTestTracer::Span) }

  context 'when activating a span' do
    it 'marks the span active' do
      scope_manager.activate(span)
      expect(scope_manager.active.span).to eq(span)
    end

    it 'changes the active span' do
      span2 = instance_spy(OpenTracingTestTracer::Span)

      scope_manager.activate(span)
      scope_manager.activate(span2)
      expect(scope_manager.active.span).to eq(span2)
    end
  end

  context 'when closing an active span' do
    it 'reverts to the previous active span' do
      span2 = instance_spy(OpenTracingTestTracer::Span)

      scope_manager.activate(span)

      scope_manager.activate(span2)
      scope_manager.active.close

      expect(scope_manager.active.span).to eq(span)
    end
  end
end
