module Punchblock
  class Client
    class ComponentRegistry
      def initialize
        @mutex = Mutex.new
        @components = Hash.new
      end
      
      def <<(component)
        @mutex.synchronize do
          @components[component.component_id] = component
        end
      end

      def find_by_id(component_id)
        @mutex.synchronize do
          @components[component_id]
        end
      end
    end
  end
end
