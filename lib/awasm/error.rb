module Awasm
  class Error
    def message
      msg = __message

      case code
      when :not_encodable
        "#{msg} #{parameter}"
      when :missing_param
        "#{msg} (#{parameter})"
      when :missing_feature
        "missing features #{features.join ', '}"
      when :invalid_access
        "#{msg} (#{instruction}/#{register})"
      else
        msg || code
      end
    end
  end
end
