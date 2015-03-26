#
# The scraper module contains all scrapers used by the SCA.
#
module Scrapers

  #
  # Returns the default logger that is used if the scraper does not define
  # its own logger.
  #
  # @return [Logger] a logger that points to a default log file.
  #
  def self.default_logger
    Scrapers.define_logger('default')
  end

  #
  # Defines a logger in the proper location.
  #
  # @param [String] file_name the name of the log file.
  #
  # @return [Logger] the logger that points to the given log file.
  #
  def self.define_logger(file_name)
    path = "#{Rails.root}/log/scrapers"

    # Creates the scrapers folder inside the log folder if necessary.
    FileUtils.mkdir_p path

    logger = Logger.new("#{path}/#{file_name}.log")
    logger.formatter = Utf8LogFormatter.new
    logger
  end

  #
  # Performs a data extraction on the Diario Oficial da União website related to a date.
  #
  # @param [Hash] args the parameters hash.
  # @option args [String] :date The date.
  # @option args [Fixnum] :book The book id.
  #
  # @return [Hash] a hash containing the result of the operation.
  #
  def self.lotery
    Scrapers::Lotery.run
  end

end

require 'scrapers/status_codes'
require 'scrapers/base_scraper'
require 'scrapers/lotery'
require 'scrapers/populator'