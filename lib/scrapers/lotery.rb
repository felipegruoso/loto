module Scrapers

  class Lotery < BaseScraper

    BASE_URL = "http://loterias.caixa.gov.br/wps/portal/loterias/landing/"

    def self.run(type, last_update)
      Lotery.new(type, last_update).safe_run
    end

    def initialize(type, last_update)
      @type        = type
      @last_update = last_update
      super(logger: Scrapers.define_logger("lotery_#{type}"))
    end

    def safe_run  
      with_exception_handling { run }
    end

    def run
      get "#{BASE_URL}#{@type}"

      output = {}
      output[:data] = {}
      values = parser('utf-8', 'iso-8859-1').css('h2')[3].text.match(/Concurso (\d+) .*\((.*?)\).*/).captures.map(&:strip)

      output[:data][:raffle_number] = values[0]
      output[:data][:date]          = values[1]
      
      if Date.parse(output[:data][:date]) <= @last_update
        return { code: Scrapers::StatusCodes::NON_EXISTENT }
      end


      output[:data][:numbers] = send("parse_#{@type}")
      output[:code]    = Scrapers::StatusCodes::SUCCESS

      output
    end

    def parse_lotofacil
      parse(@type)
    end

    def parse_lotomania
      parse(@type)
    end

    def parse_megasena
      parser('utf-8', 'iso-8859-1').css(".numbers li").map(&:text)
    end

    def parse(type)
      parser('utf-8', 'iso-8859-1').css(".#{@type}").text.gsub(/[[:space:]]+/, ' ').strip.split(" ")
    end

  end

end