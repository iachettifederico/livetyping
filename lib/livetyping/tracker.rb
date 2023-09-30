# frozen_string_literal: true

require "pathname"

module Livetyping
  class Tracker
    def self.load
      new
    end

    def start
      @tracer.enable
      @started = true
    end

    def started?
      @started
    end

    def stop
      @started = false
      @tracer.disable
    end

    def whats_on(source_file:, line:, column:)
      found = @something.find { |hash|
        hash.dig(:source_file) == source_file &&
          hash.dig(:line) == line
      }

      if found
        the_binding = found[:binding]
        code = found[:code]
        if the_binding.local_variables.include?(token_under(code, column))
        {
          types: [
            the_binding.local_variable_get(:a_local_variable).class.to_s
          ],
        }
        else
          { types: [] }
        end
      else
        { types: [] }
      end
    end

    def project_root
      Pathname(__dir__).join("../../").expand_path
    end

    private

    def initialize
      @started = false
      @old_trace_point = nil
      @something = []
      @tracer = TracePoint.new(:line) do |trace_point|
        do_something(trace_point)
      end
    end

    def do_something(trace_point)
      if @old_trace_point
        @something << {
          binding: @old_trace_point.binding,
          **trace_point_location(@old_trace_point),
        }
      end

      @old_trace_point = trace_point
    end

    def trace_point_location(trace_point)
      regex = /^(.+):(\d+):.+/
      source_file = trace_point.path
      line = trace_point.lineno
      code = if source_file =~ /<internal:.+>/
               "<internal implementation>"
             else
               File.readlines(source_file)[line - 1]
             end

      {
        code:        code,
        source_file: source_file,
        line:        line,
      }
    end

    def token_under(code, column)
      # ap code
      # ap code[column]
    end
  end
end
