module MyAASM
  class StateMachine
    attr_accessor :states, :events

    def initialize
      @states = []
      @events = {}
    end

    def add_state(state_name)
      @states << state_name
    end

    def add_event(event_name)
      @events[event_name] = []
    end
  end
end