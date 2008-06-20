#http://arika.org/diary/20080619#p01
if defined?(ActiveSupport) &&
    defined?(ActiveSupport::Multibyte) &&
    defined?(ActiveSupport::Multibyte::Chars)
  mc = ActiveSupport::Multibyte::Chars.new("")
  begin
    "" + mc
  rescue ArgumentError
    raise unless mc.method(:respond_to?).arity == 1 
    class ActiveSupport::Multibyte::Chars
      def respond_to?(method, ip = false) 
        super || @string.respond_to?(method, ip) || handler.respond_to?(method, ip) ||
          (method.to_s =~ /(.*)!/ && handler.respond_to?($1, ip)) || false
      end
    end
  end
end
