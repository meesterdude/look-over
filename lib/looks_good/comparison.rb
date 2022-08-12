require 'mini_magick'
module LooksGood
  class Comparison

    attr_accessor :diff_image, :diff_image_file, :actual_image, :expected_image

    def initialize(actual_image, expected_image, within=LooksGood::Configuration.default_within)
      @actual_image = actual_image
      @expected_image = expected_image
      @comparison = compare_image
      @within = within
      # within is a float of % image difference between the two images
      @match = @comparison <= @within
      @diff_image =LooksGood::Image.new(@diff_image_file, @expected_image.file_name)
    end

    def matches?
      @match
    end

    def within
      @within
    end

    def percent_difference
      @comparison
    end

    def compare_image
      compare_images_with_same_size? ? compare_images_with_same_size : compare_images_with_different_size
    end

    def compare_images_with_same_size
      images_to_compare = prep_images_for_comparison
      mini_compare(images_to_compare)
    end

    def compare_images_with_different_size
      row = [@actual_image.image.rows, @expected_image.image.rows].max
      column = [@actual_image.image.columns, @expected_image.image.columns].max

      images_to_compare = prep_images_for_comparison do |image|
        expanded_image = image.extent(column, row)
        expanded_image.background_color = 'white'
        expanded_image
      end
      mini_compare(images_to_compare)
    end

    def compare_images_with_same_size?
      @actual_image.image.rows == @expected_image.image.rows && @actual_image.image.columns == @expected_image.image.columns
    end

    # drop in refactor to utilize mini_magick. 
    # returns a float % of difference 
    # TODO: remove rmagick
    def mini_compare(images)
      actual_image, expected_image = images
      actual_image.write(actual_image.filename)
      pixel_difference_count = nil
      MiniMagick::Tool::Compare.new(whiny: false) do |comp|
        comp.fuzz(LooksGood::Configuration.fuzz)  
        comp.metric("AE")
        comp << actual_image.filename  
        comp << expected_image.filename
        diff_file_name = File.join(LooksGood::Configuration.path(:diff), @actual_image.file_name)
        FileUtils::mkdir_p(File.dirname(diff_file_name)) unless File.exists?(diff_file_name)
        comp << diff_file_name
        comp.call do |stdout, stderr, status|
         pixel_difference_count = stderr
        end
        @diff_image_file = Magick::Image.read(diff_file_name).first
      end
      pixel_difference_count.to_f / (expected_image.rows * expected_image.columns)
    end

    def prep_images_for_comparison
      [
          @actual_image,
          @expected_image,
      ].collect do |looks_good_image|
        image = looks_good_image.image.clone
        image = yield image if block_given?

        # Important: ensure the image 0,0 is reset to the top-left of the image before comparison
        image.offset = 0
        image
      end
    end

  end
end
