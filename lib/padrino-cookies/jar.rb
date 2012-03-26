# encoding: UTF-8
module Padrino
  module Cookies
    class Jar
      include Enumerable

      # @private
      def initialize(app)
        @response = app.response
        @request  = app.request
        @cookies  = app.request.cookies

        if app.settings.respond_to?(:cookie_secret)
          @secret = app.settings.cookie_secret
        elsif app.settings.respond_to?(:session_secret)
          @secret = app.settings.session_secret
        end

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
      #   cookie[:remembrance]
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
      # @raise [Overflow]
      #   Raised when the value of the cookie exceeds the maximum size
      #
      # @example
      #   cookie[:remembrance] = '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #
      # @since 0.1.0
      # @api public
      def []=(name, options)
        unless options.is_a?(Hash)
          options = { value: options }
        end

        raise Overflow if options[:value].size > MAX_COOKIE_SIZE

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
      #   cookie.permanent[:remembrance] = '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #
      # @since 0.1.0
      # @api public
      def permanent
        @permanent ||= PermanentJar.new(self, @secret)
      end

      ###
      # Signs a cookie with a cryptographic hash so it cannot be tampered with
      #
      # @example
      #   cookie.signed[:remembrance] = '71ab53190d2f863b5f3b12381d2d5986512f8e15b34d439e6b66e3daf41b5e35'
      #
      # @since 0.1.1
      # @api public
      def signed
        @signed ||= SignedJar.new(self, @secret)
      end
    end # Jar

    class PermanentJar # @private
      def initialize(parent_jar, secret)
        @parent_jar = parent_jar
        @secret = secret
      end

      def []=(name, options)
        options = { value: options } unless options.is_a?(Hash)
        options[:expires] = 1.year.from_now
        @parent_jar[name] = options
      end

      def signed
        @signed ||= SignedJar.new(self, @secret)
      end

      def method_missing(method, *args, &block)
        @parent_jar.send(method, *args, &block)
      end
    end # PermanentJar

    class SignedJar # @private
      def initialize(parent_jar, secret)
        if secret.blank? || secret.size < 64
          raise ArgumentError, 'cookie_secret must be at least 64 characters long'
        end

        @parent_jar = parent_jar
        @message_verifier = ActiveSupport::MessageVerifier.new(secret)
      end

      def [](name)
        if value = @parent_jar[name]
          @message_verifier.verify(value)
        end
      rescue
        nil
      end

      def []=(name, options)
        options = { value: options } unless options.is_a?(Hash)
        options[:value] = @message_verifier.generate(options[:value])
        @parent_jar[name] = options
      end

      def permanent
        @permanent ||= PermanentJar.new(self, @secret)
      end

      def method_missing(method, *args, &block)
        @parent_jar.send(method, *args, &block)
      end
    end # SignedJar
  end # Cookies
end # Padrino