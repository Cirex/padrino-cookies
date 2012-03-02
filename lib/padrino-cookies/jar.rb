# encoding: UTF-8
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/date/calculations'

module Padrino
  module Cookies
    class Jar
      include Enumerable

      # @private
      def initialize(app)
        @response = app.response
        @request  = app.request
        @cookies  = app.request.cookies

        @options = {
              path: '/',
          httponly: true,
            secure: @request.secure?
        }
      end

      ###
      # Returns the value of the specified cookie
      #
      # @return [String]
      #   Value of the cookie
      #
      # @example
      #   cookies[:remembrance]
      #   # => '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #
      # @since 0.1.0
      # @api public
      def [](name)
        @cookies[name.to_s]
      end

      ###
      # Sets the specified cookie
      #
      # @overload []=(name, value)
      #   @param [Symbol] name
      #     The name of the cookie being set
      #   @param [String] value
      #     The value of the cookie being set
      #
      # @overload []=(name, options)
      #   @param [Symbol] name
      #     The name of the cookie being set
      #   @param [Hash] options
      #     The options to set along with this cookie
      #
      #   @option options [String] :value
      #     The value of the cookie being set
      #   @option options [Time] :expires
      #     The time when this cookie expires
      #   @option options [Boolean] :httponly (true)
      #     Should the cookie be accessible to the HTTP protocol only
      #   @option options [Boolean] :secure
      #     Should the cookie only be sent over secure connections such as HTTPS
      #   @option options [String] :path ('/')
      #     The scope in which this cookie is accessible
      #   @option options [String] :domain
      #     The scope in which this cookie is accessible
      #
      # @example
      #   cookies[:remembrance] = '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #
      # @since 0.1.0
      # @api public
      def []=(name, options)
        unless options.is_a?(Hash)
          options = { value: options }
        end

        @response.set_cookie(name, @options.merge(options))
        @cookies[name.to_s] = options[:value]
      end

      ###
      # Returns an array of cookies that have been set
      #
      # @return [Array<String>]
      #   Cookies set
      #
      # @example
      #   cookies.keys
      #   # => ['remembrance']
      #
      # @since 0.1.0
      # @api public
      def keys
        @cookies.keys
      end

      ###
      # Returns whether or not the specified cookie is set
      #
      # @return [Boolean]
      #   *true* if it is, *false* otherwise
      #
      # @example
      #   cookie.key?(:remembrance)
      #   # => true
      #
      # @since 0.1.0
      # @api public
      def key?(name)
        @cookies.key?(name.to_s)
      end
      alias_method :has_key?, :key?
      alias_method :include?, :key?

      ###
      # Deletes the specified cookie
      #
      # @return [String]
      #   Value of the deleted cookie
      #
      # @example
      #   cookies.delete :remembrance
      #
      # @since 0.1.0
      # @api public
      def delete(name)
        @response.delete_cookie(name)
        @cookies.delete(name.to_s)
      end

      ###
      # Deletes all cookies that are currently set
      #
      # @example
      #   cookies.clear
      #
      # @since 0.1.0
      # @api public
      def clear
        @cookies.each_key { |name| delete(name) }
      end

      ###
      # Returns whether or not any cookies have been set
      #
      # @return [Boolean]
      #   *true* if cookies are set, *false* otherwise
      #
      # @example
      #   cookies.empty?
      #   # => true
      #
      # @since 0.1.0
      # @api public
      def empty?
        @cookies.empty?
      end

      ###
      # Returns the total amount of cookies that have been set
      #
      # @return [Integer]
      #   Total cookies set
      #
      # @example
      #   cookies.length
      #   # => 2
      #
      # @since 0.1.0
      # @api public
      def length
        @cookies.length
      end
      alias_method :size, :length

      ###
      # Iterates through set cookies
      #
      # @example
      #   cookies.each do |key, value|
      #     # ...
      #   end
      #
      # @since 0.1.0
      # @api public
      def each(&block)
        @cookies.each(&block)
      end

      # @since 0.1.0
      # @api public
      def to_hash
        @cookies.dup
      end

      # @since 0.1.0
      # @api public
      def to_s
        @cookies.to_s
      end

      ###
      # Sets a permanent cookie
      #
      # @example
      #   cookies.permanent[:remembrance] = '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #
      # @since 0.1.0
      # @api public
      def permanent
        @permanent ||= PermanentJar.new(self)
      end
    end # Jar

    class PermanentJar # @private
      def initialize(parent_jar)
        @parent_jar = parent_jar
      end

      def []=(key, options)
        unless options.is_a?(Hash)
          options = { value: options }
        end

        options[:expires] = 1.year.from_now
        @parent_jar[key] = options
      end

      def method_missing(method, *args, &block)
        @parent_jar.send(method, *args, &block)
      end
    end # PermanentJar
  end # Cookies
end # Padrino