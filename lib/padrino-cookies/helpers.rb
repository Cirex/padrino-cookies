# encoding: UTF-8
module Padrino
  module Cookies
    module Helpers
      ###
      # Returns the cookie storage object
      #
      # @return [Jar]
      #   ...Nom ....Nom ....Nom
      #
      # @example
      #   cookie[:remembrance] = '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #   cookies.delete :remembrance
      #
      # since 0.1.0
      # @api public
      def cookies
        @cookie_jar ||= Jar.new(self)
      end
      alias_method :cookie, :cookies
    end # Helpers
  end # Cookies
end # Padrino