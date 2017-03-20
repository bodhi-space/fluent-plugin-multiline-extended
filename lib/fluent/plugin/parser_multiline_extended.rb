require 'fluent/parser'

module Fluent
  class TextParser
    class ExtendedMultilineParser < MultilineParser
      
      Plugin.register_parser('multiline_extended', self)

      config_param :splitter_regex, :string, :default => nil
      config_param :splitter_matches, :string, :default => nil

      def configure(conf)
        @splitter_regex = conf.delete('splitter_regex')
        @splitter_regex = Regexp.new(@splitter_regex[1..-2], Regexp::MULTILINE) unless @splitter_regex.nil?
        @splitter_matches = conf.delete('splitter_matches')
        super(conf)
      end

      def has_splitter?
        !@splitter_regex.nil?
      end

      def splitter(glob)
        events = []
        saved = ''
        remainder = glob
        matched = ''

        until matched.empty? and glob.empty? do
          chunk, matched, glob = glob.partition(@splitter_regex)

          if not matched.empty?
            if @splitter_matches and @splitter_matches == 'head'
              events << saved + chunk unless saved.empty? and chunk.empty?
              saved = matched
              remainder = matched + glob
            elsif @splitter_matches and @splitter_matches == 'tail'
              events << chunk + matched
              remainder = glob
            else
              events << chunk
              remainder = glob
            end
          end
            
        end

        events << remainder
        return events

      end
    end
  end
end
