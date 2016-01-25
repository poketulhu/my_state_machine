require_relative 'state_machine'

module MyAASM

  class TransitionError < RuntimeError; end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    attr_reader :state_machine

    def my_aasm(&block)
      alias_method :original_initialize, :initialize
      define_method :initialize do |*args|
        original_initialize(*args[0..-2])
        instance_variable_set('@inst_state', :init)
        self.class.send(:define_method, 'inst_state') { instance_variable_get '@inst_state' }
      end

      @state_machine = StateMachine.new

      instance_eval(&block) if block
    end

    def state(state_name)
      @state_machine.add_state(state_name)

      define_method "#{state_name}?" do
        @inst_state == "#{state_name}".to_sym
      end

      define_method "#{state_name}" do
        instance_variable_set('@inst_state', "#{state_name}".to_sym)
      end
    end

    def event(event_name, options ={}, &block)
      @state_machine.add_event(event_name)
      @cur_event = event_name

      define_method "may_#{event_name}?" do
        !may_fire?(event_name).empty?
      end

      define_method "#{event_name}" do
        result = may_fire?(event_name)
        !result.empty? ? @inst_state = result.first[:to] : raise(TransitionError, 'Cannot change state')
      end

      class_eval <<-EORUBY, __FILE__, __LINE__ + 1
        private

        def may_fire?(event_name)
          state_machine = self.class.class_eval { @state_machine }
          result = state_machine.events[event_name].select do |t|
            t[:from].is_a?(Symbol) ? t[:from] == @inst_state : t[:from].include?(@inst_state)
          end
        end
      EORUBY

      instance_eval(&block) if block
    end

    def transitions(options)
      @state_machine.events[@cur_event] << { from: options[:from], to: options[:to] }
    end
  end
end