# encoding: UTF-8
require 'padrino-core'
FileSet.glob_require('padrino-cookies/**/*.rb', __FILE__)

module Padrino
  module Cookies
    class << self
      # @private
      def registered(app)
        app.helpers Helpers
      end
    end # self
  end # Cookies
end # Padrino