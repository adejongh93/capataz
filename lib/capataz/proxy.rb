
module Capataz

  class Proxy

    instance_methods.each do |m|
      if m !~ /^(__|instance_eval|object_id)/
        class_eval("
        def #{m}(*args, &block)
          method_missing(:#{m}, *args, &block)
        end")
      end
    end

    def initialize(obj, options = {})
      @obj = obj
      if (@options = options || {})[:constant] && !Capataz.allowed_constant?(obj)
        fail "Illegal access to constant #{obj}"
      end
    end

    def method(sym)
      if Capataz.instance_response_to?(@obj, symbol)
        @obj.method(sym)
      else
        nil
      end
    end

    def method_missing(symbol, *args, &block)
      if Capataz.instance_response_to?(@obj, symbol)
        @obj.send(symbol, *args, &block)
      else
        fail NoMethodError, "undefined method #{symbol} for #{@obj}"
      end
    end

    def is_a?(type)
      if type.capataz_proxy?
        @obj.is_a?(type.capataz_slave)
      else
        @obj.is_a?(type)
      end
    end

    def capataz_proxy?
      true
    end

    def capataz_slave
      @obj
    end

    def class
      @obj.class
    end

    def respond_to?(*args)
      Capataz.instance_response_to?(@obj, *args)
    end
  end

  class HashProxy < Proxy

    def []=(key, value)
      key = key.capataz_slave if key.capataz_proxy?
      @obj[key] = value
    end

    def [](key)
      key = key.capataz_slave if key.capataz_proxy?
      value = @obj[key]
      value.capataz_proxy? ? value.capataz_slave : value
    end
  end
end