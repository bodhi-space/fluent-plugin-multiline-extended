require 'fluent/plugin/in_tail'
module Fluent
  class NewTailInput < Fluent::Plugin::TailInput

    Plugin.register_input('tail_multiline_extended', self)

    def parse_multilines(lines, tail_watcher)
      if @parser.has_splitter?
        es = MultiEventStream.new
        tail_watcher.line_buffer_timer_flusher.reset_timer if tail_watcher.line_buffer_timer_flusher
        lb = tail_watcher.line_buffer.to_s + (lines.is_a?(Array) ? lines.select {|e| e.is_a?(String)}.join('') : '')
        tail_watcher.line_buffer = ''

        if not lb.empty?
          events = @parser.splitter(lb)
          tail_watcher.line_buffer = events.pop
          events.each do |event|
            @parser.parse(event) do |time, record|
              convert_line_to_event(event, es, tail_watcher) if time && record
            end
          end
        end
        es
      else
        super(lines, tail_watcher)
      end
    end

  end
end
