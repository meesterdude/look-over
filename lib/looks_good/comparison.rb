module LooksGood
  class Comparison

    attr_accessor :diff_image, :actual_image, :expected_image

    def initialize(actual_image, expected_image, within=0.01)
      @actual_image = actual_image
      @expected_image = expected_image
      @comparison = compare_image
      @within = within
      # within is a float of % image difference between the two images
      @match = @comparison[1] <= @within
      @diff_image =LooksGood::Image.new(@comparison.first, @expected_image.file_name) unless @matches
    end

    def matches?
      @match
    end

    def within
      @within
    end

    def percent_difference
      @comparison[1]
    end

    def compare_image
      compare_images_with_same_size? ? compare_images_with_same_size : compare_images_with_different_size
    end

    def compare_images_with_same_size
      images_to_compare = prep_images_for_comparison
      images_to_compare.first.compare_channel(images_to_compare.last, Magick::PeakAbsoluteErrorMetric, Magick::AllChannels) do
        self.highlight_color = Magick::Pixel.new(65300,100,0,38000)
        self.lowlight_color = Magick::Pixel.new(0,65300,1000,60000)
      end
    end

    def compare_images_with_different_size
      row = [@actual_image.image.rows, @expected_image.image.rows].max
      column = [@actual_image.image.columns, @expected_image.image.columns].max

      images_to_compare = prep_images_for_comparison do |image|
        expanded_image = image.extent(column, row)
        expanded_image.background_color = 'white'
        expanded_image
      end
    images_to_compare.first.compare_channel(images_to_compare.last, Magick::PeakAbsoluteErrorMetric) do
        self.highlight_color = Magick::Pixel.new(65300,100,0,38000)
        self.lowlight_color = Magick::Pixel.new(0,65300,1000,60000)
      end
    end

    def compare_images_with_same_size?
      @actual_image.image.rows == @expected_image.image.rows && @actual_image.image.columns == @expected_image.image.columns
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
