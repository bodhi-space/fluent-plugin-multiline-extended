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

        until glob.empty? do
          chunk, matched, glob = glob.partition(@splitter_regex)

          if [ "head", "tail" ].include?(@splitter_matches)
            if @splitter_matches == 'tail'
              events << "#{chunk}#{matched}"
            else
              events << "#{saved}#{chunk}"
              saved = matched
            end
          else
            events << chunk
          end

        end

        return events
      end

    end
  end
end
