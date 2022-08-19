require 'rmagick'
require 'capybara'
require 'capybara/dsl'

require 'looks_good/configuration'
require 'looks_good/image'
require 'looks_good/comparison'
require 'looks_good/capture_element'
require 'looks_good/rspec_config'

module LooksGood
  class << self

    def check(expected_reference_filename, actual_element, within: LooksGood::Configuration.default_within)
       result = match_result(expected_reference_filename, actual_element, within: within)
       result
    end

    def match_result(expected_reference_filename, actual_element, within:)
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
          result_hash[:message] = %Q[view a visual diff image: open #{comparison.diff_image.path(:diff)}\n
HOW TO FIX:\n 
- cp #{comparison.diff_image.path(:candidate)} #{@expected_reference_file}
or
- LOOKS_GOOD=true rspec ...
--
#{LooksGood::Configuration.custom_failure_message}]
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

    def save_image_as_candidate(image)
      image.save(:candidate)
      raise "The design reference #{image.file_name} does not exist, #{image.path(:candidate)} " +
      "is now available to be used as a reference. Copy candidate to root reference_image_path to use as reference"
    end

    def save_reference
      sleep 0.5 # ensures page/browser stability of focus effects etc inherent in browsers
      ImageFromElement.new(@actual_element,@expected_reference_filename).verify_and_save
    end

    def cleanup
      FileUtils.remove_dir(LooksGood::Configuration.path(:tmp)) if File.directory?(LooksGood::Configuration.path(:tmp))
      FileUtils.remove_dir(LooksGood::Configuration.path(:diff)) if File.directory?(LooksGood::Configuration.path(:diff))
      FileUtils.remove_dir(LooksGood::Configuration.path(:candidate)) if File.directory?(LooksGood::Configuration.path(:candidate))
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

