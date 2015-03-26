require 'fileutils'
require 'zip'

module Scrapers

  class Populator < BaseScraper

    BASE_URL = "http://www1.caixa.gov.br/loterias/_arquivos/loterias/"

    TRANSLATOR = {
      "lotofacil" => { download: "D_lotfac", quantity_of_numbers: 15 },
      "lotomania" => { download: "D_lotoma", quantity_of_numbers: 20 },
      "megasena"  => { download: "D_mgsasc", quantity_of_numbers: 6 }
    }

    ZIP_DIR = "#{Rails.root}/tmp/zips/"
    HTML_DIR = "#{Rails.root}/tmp/htmls/"

    def self.run(game)
      Populator.new(game).safe_run
    end

    def initialize(game)
      @game = game
      super(logger: Scrapers.define_logger("populator_#{@game}"))
    end

    def safe_run
      with_exception_handling { run }
    end

    def run
      get "#{BASE_URL}#{TRANSLATOR[@game][:download]}.zip"
      puts "#{BASE_URL}#{TRANSLATOR[@game][:download]}.zip"

      FileUtils.mkpath(ZIP_DIR)
      filename = "#{ZIP_DIR}#{@game}.zip"
      
      File.open(filename, "wb") do |f|
        f.write(body)
      end

      extracted_file = "#{HTML_DIR}#{@game}.htm"
      FileUtils.mkpath(HTML_DIR)
      puts "==============================FILENAME"
      puts filename
      Zip::File.open(filename) do |zip_file|
        zip_file.each do |entry|
          FileUtils.rm_rf(extracted_file)
          if entry.name.match(/\.HTM/i)
            $e = entry
            entry.extract(extracted_file) 
          end
        end
      end
      puts extracted_file

      f = File.open(extracted_file)
      doc = Nokogiri::HTML(f)
      f.close

      output = {}
      output[:data] = parse_doc(doc)
      output[:code] = Scrapers::StatusCodes::SUCCESS

      output
    end

    def parse_doc(doc)
      results = []
      doc.css('tr').each do |tr|
        result = tr.css('td')[0...(TRANSLATOR[@game][:quantity_of_numbers] + 2)].map(&:text)
        puts result
        if result.size == (TRANSLATOR[@game][:quantity_of_numbers] + 2)
          hsh = {
            raffle_number: result[0],
            date:          result[1],
            numbers:       result[2..result.size].sort
          }
          results << hsh
        end
      end

      results
    end

  end

end