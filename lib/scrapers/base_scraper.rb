module Scrapers

  #
  # This is the Base scraper class.
  # All scrapers should inherit from it.
  #
  class BaseScraper

    #
    # @!attribute agent
    #   @return [Mechanize] the scraper's agent.
    #
    # @!attribute response_code
    #   @return [String] the last request's HTTP response code.
    #
    attr_accessor :agent, :response_code

    #
    # How many times the scraper will retry, if retrying
    # is active.
    #
    MAX_ATTEMPTS = 2

    #
    # Creates a new instance of the BaseScraper class.
    #
    # @param [Hash] opts a hash of options used to initialize the Scraper.
    #
    # @return [BaseScraper] a new instance of `BaseScraper`.
    #
    def initialize(opts = {})
      opts = {
        agent:  Mechanize.new,
        logger: Scrapers.default_logger,
        cache:  {}
      }.merge!(opts)

      @logger  = opts[:logger]
      @cache   = opts[:cache]

      initialize_agent agent

    end

    #
    # Makes a GET request to the given URL.
    #
    # @param [String] url the URL to make the GET request to.
    # @param [Hash] args a hash that is merged with the URL params.
    #
    # @return [String] the body of the downloaded page.
    #
    def get(url, args = {})
      make_request(:get, url, args)
    end

    #
    # Makes a POST request to the given URL.
    #
    # @param [String] url the URL to make the POST request to.
    # @param [Hash] args a hash that is merged with the URL params.
    #
    # @return [String] the body of the downloaded page.
    #
    def post(url, args = {})
      make_request(:post, url, args)
    end

    #
    # Gets the agent's current page.
    #
    # @return [Mechanize::Page] the agent's current page.
    #
    def page
      return @cache[:page] unless @cache[:page].nil?

      @cache[:page] = @agent.try(:page)
    end

    #
    # Parses the page's body, encoding it according to `dst_encoding` and `src_encoding`.
    #
    # @param [String] dst_encoding the encoding to which the content should be converted.
    # @param [String] src_encoding the encoding of the source page.
    #
    # @return [String] the parsed page's body.
    #
    def parser(dst_encoding = 'utf-8', src_encoding = nil)
      return @cache[:parser] unless @cache[:parser].nil?

      if dst_encoding
        # Converts the page's body to UTF-8.
        return @cache[:parser] = Nokogiri::HTML(body.encode(dst_encoding, src_encoding))

      elsif (@cache[:parser] = page.try(:parser))
        # If no source encoding is given, does no conversion.
        return @cache[:parser]
      end

      '' # Default return.
    end

    #
    # Returns the raw page's body.
    #
    # @param [String] dst_encoding the encoding to which the content should be converted.
    # @param [String] src_encoding the encoding of the source page.
    #
    # @return [String] the raw page's body.
    #
    def body(dst_encoding = 'utf-8', src_encoding = nil)
      return @cache[:body] unless @cache[:body].nil?

      if page
        if src_encoding
          # Converts the page's body to UTF-8.
          return (@cache[:body] = page.body.encode(dst_encoding, src_encoding))
        end

        return (@cache[:body] = page.body)
      end

      '' # Default return.
    end

    #
    # Expires the cache entries associated with the given keys.
    #
    # @param [Array<Symbol>] keys the keys whose values will be expired from the cache.
    #
    def expire_cache_keys *keys
      keys.each { |k| @cache.delete k.to_sym }
    end

    #
    # Protected methods.
    #
    protected

    #
    # Initializes the Mechanize agent.
    #
    # @param [Mechanize] agent the scraper's agent.
    #
    def initialize_agent(agent = Mechanize.new)
      @agent               = (agent.nil? ? Mechanize.new : agent)
      @agent.log           = Logger.new("#{Rails.root}/log/scrapers/mechanize.log")
      @agent.log.formatter = Utf8LogFormatter.new
      @agent.user_agent    = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:7.0.1) Gecko/20100101 Firefox/7.0.1'
      # @agent.max_history  = 1
    end

    #
    # Implements a generic request that can be performed via GET or POST.
    #
    # @param [Symbol] method :get or :post.
    # @param [String] url the URL to be called.
    # @param [Hash] args a hash that is merged with the URL params.
    #
    # @return [String] the current page's content.
    #
    def make_request(method, url, args = {})
      raise Exception.new("Unsupported HTTP method.") unless [:get, :post].include? method.to_sym

      process_params(args)

      begin

        # This timeout logic is the same as the one in TimeoutableRequest.
        # Please refer to that file to understand why we're using a new
        # thread.
        thread = nil
        begin
          Timeout.timeout(10) do
            thread = Thread.new { @agent.send(method, url, args) }
            thread.join
          end
        ensure
          thread.kill
        end

        # Expires outdated cache entries.
        expire_cache_keys :page, :body, :parser

        @response_code = @agent.page.code.to_i
        return @agent.page.body

      rescue Mechanize::ResponseCodeError => exc
        log_exception(exc, url: url, method: method, args: args)

        @response_code = exc.response_code.to_i
        @error_page = exc.page
      rescue Timeout::Error => exc
        log_exception(exc, url: url, method: method, args: args)
        raise
      rescue Exception => exc
        log_exception(exc, url: url, method: method, args: args)
      end
    end

    #
    # Logs an exception.
    #
    # @param [Exception] exception the exception to be logged.
    # @param [Hash] opts a hash containing optional data for the log file.
    #
    def log_exception(exception, opts = {})
      opts = {
        url:    'unknown URL',
        method: 'unknown method',
        args:   'unknown args'
      }.merge(opts)

      @logger.debug("\nFailed to download #{opts[:url]} - #{opts[:args]} (#{opts[:method]})")
      @logger.debug("Agent: #{@agent.inspect}")
      @logger.debug(exception)
      @logger.debug(exception.backtrace.join("\n"))
    end

    #
    # Process parameters. This method just makes sure that the request
    # arguments are not nil. Scrapers that have specific needs should
    # override this method and extend functionality.
    #
    # @param [Hash] args the arguments to be sent along with the request.
    #
    def process_params(args = {})
      args ||= {}
    end

    #
    # Contingency method that handles exceptions and logs them properly.
    #
    # @return [Hash] the result of the operation.
    #
    def with_exception_handling
      yield
    rescue Timeout::Error => exc
      return { code: Scrapers::StatusCodes::BLOCKED_REQUEST }
    rescue Exception => exc
      @logger.error("\n#{self.class} error")
      @logger.error(exc)
      @logger.error(exc.backtrace.join("\n"))
      @logger.error(body)

      return { code: Scrapers::StatusCodes::INTERNAL_ERROR }
    end

    #
    # Defines a set of common options that will be used by the
    # majority of the scrapers.
    #
    # @return [Hash] the set of options.
    #
    def base_opts
      { attempt: 1, retry: false }
    end

  end

end
