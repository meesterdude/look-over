require 'rmagick'
require 'capybara'
require 'capybara/dsl'

require 'looks_good/configuration'
require 'looks_good/image'
require 'looks_good/comparison'
require 'looks_good/capture_element'

module LooksGood
  class << self

    def match_result(expected_reference_filename, actual_element, within: 0.01)
      result_hash = {}
      @actual_element = actual_element
      @expected_reference_filename = expected_reference_filename
      @expected_reference_file = (File.join(LooksGood::Configuration.path(:reference), expected_reference_filename))


      if !File.exists?(@expected_reference_file) || ENV["LOOKS_GOOD"]
        save_reference
        result_hash[:result] = true
        return result_hash
      else
        reference_file = LooksGood::ImageFromFile.new(expected_reference_filename)
        comparison = compare_until_match(actual_element, reference_file, within: within)
        result_hash[:comparison] = comparison
        result_hash[:percent_difference] = comparison.percent_difference
        matches = comparison.matches?
        if !matches
          comparison.actual_image.save(:candidate)
          save_image_as_diff(comparison.diff_image)
          result_hash[:message] = "view visual diff image #{comparison.diff_image.path(:diff)}\n" +
                    "New reference #{comparison.diff_image.path(:candidate)} can be used to fix the spec or by running rspec with LOOKS_GOOD=true"
          result_hash[:result] = false
          result_hash
        else
          result_hash[:result] = true
          result_hash
        end
      end
    end

    def compare_until_match(actual_element, reference_file, within:, max_no_tries: LooksGood::Configuration.max_no_tries, sleep_time: LooksGood::Configuration.sleep_between_tries)
      max_no_tries.times do |i|
        actual_image = LooksGood::ImageFromElement.new(actual_element, reference_file.file_name)
        @comparison = LooksGood::Comparison.new(actual_image, reference_file, within)
        match = @comparison.matches?
        if !match
          sleep sleep_time
          #TODO: Send to logger instead of puts
          i += 1
          puts "Tried to match #{i} times"
        else
          return(@comparison) 
        end
      end
      @comparison
    end

    def save_image_as_diff(image)
      image.save(:diff)
     
    end

    def save_image_as_candidate(image)
      image.save(:candidate)
      raise "The design reference #{image.file_name} does not exist, #{image.path(:candidate)} " +
      "is now available to be used as a reference. Copy candidate to root reference_image_path to use as reference"
    end

    def save_reference
      ImageFromElement.new(@actual_element,@expected_reference_filename).verify_and_save
    end

    def config(&block)
      begin
        config_class = LooksGood::Configuration
        raise "No block provied" unless block_given?
        block.call(config_class)
      rescue
         raise "Config block has changed. Example: LooksGood.config {|c| c.reference_image_path = 'some/path'}. Please see README"
      end
    end

  end
end

