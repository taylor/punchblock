module Blather
  class Stanza
    class Presence
      alias :event :rayo_node

      def rayo_event?
        event.is_a? Punchblock::Event
      end
    end
  end
end
