# encoding: UTF-8
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'active_support/message_verifier'

require 'padrino-core'
FileSet.glob_require('padrino-cookies/**/*.rb', __FILE__)

module Padrino
  module Cookies
    MAX_COOKIE_SIZE = 4096

    class Overflow < ArgumentError
      def http_status
        500
      end
    end

    class << self
      # @private
      def registered(app)
        app.helpers Helpers
      end
    end # self
  end # Cookies
end # Padrino