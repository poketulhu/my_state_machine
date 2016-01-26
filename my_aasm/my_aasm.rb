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
        instance_variable_set('@state', :init)
        self.class.send(:define_method, 'state') { instance_variable_get '@state' }
      end

      @state_machine = StateMachine.new

      instance_eval(&block) if block
    end

    def state(state_name)
      @state_machine.add_state(state_name)

      define_method "#{state_name}?" do
        @state == "#{state_name}".to_sym
      end

      define_method "#{state_name}" do
        instance_variable_set('@state', "#{state_name}".to_sym)
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
        if !result.empty?
          result.select { |t| t[:conditional] == true }.empty? ?
          @state = result.select { |t| t[:conditional] == nil }.first[:to] :
          @state = result.select { |t| t[:conditional] == true }.first[:to]
        else
          raise(TransitionError, 'Cannot change state')
        end
        after_callback(options[:after]) if options[:after]
      end

      class_eval <<-EORUBY, __FILE__, __LINE__ + 1
        private

        def may_fire?(event_name)
          state_machine = self.class.class_eval { @state_machine }
          result = state_machine.events[event_name].select do |t|
            t[:from].is_a?(Symbol) ? t[:from] == @state : t[:from].include?(@state)
          end
        end

        def after_callback(method_name)
          send(method_name)
        end

      EORUBY

      instance_eval(&block) if block
    end

    def transitions(options)
      conditional = options[:if] && send(options[:if])
      @state_machine.events[@cur_event] << { from: options[:from], to: options[:to], conditional: conditional }
    end
  end
end