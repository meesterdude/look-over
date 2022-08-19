require 'logger'

module LooksGood
  module Configuration

    class << self

      attr_accessor :fuzz, :reference_image_path, :max_no_tries, :sleep_between_tries, 
                    :browser_folders, :default_within, :scale_amount, :disable_scaling

      attr_reader :paths

      def reference_image_path
        @reference_image_path ||= default_reference_path
        @browser_folders ? (reference_path_with_browser_folders) : @reference_image_path
      end

      def default_within
        @default_within ||= 0.0001
      end

      # allows retina mac screenshots to be scaled to expected size
      def scale_amount
        @scale_amount ||= 0.5 
      end

      def max_no_tries
        @max_no_tries ||= 2
      end

      def disable_scaling
        @disable_scaling ||= false
      end

      def fuzz
        @fuzz ||= "10%"
      end

      def sleep_between_tries
        @sleep_between_tries ||= 0.1
      end

      def path(type)
        paths =  {:reference => reference_image_path,
                  :tmp => File.join(reference_image_path, 'tmp', 'tmp'),
                  :candidate => File.join(reference_image_path, 'tmp', 'candidate'),
                  :diff => File.join(reference_image_path, 'tmp', 'diff')
                 }
        paths[type]
      end

      def default_reference_path
        begin
          reference_image_path = File.join(Rails.root, 'spec/screenshots')
        rescue
          reference_image_path = 'spec/screenshots'
          puts "Currently defaulting to #{@reference_image_path}. Overide this by setting reference_image_path=[refpath] in your configuration block"
        end
        reference_image_path
      end

      def reference_path_with_browser_folders
        begin
          reference_images_path = File.join(@reference_image_path, browser)
        rescue
          reference_images_path = @reference_image_path
        end
        reference_images_path
      end

      def browser
        begin
          browser = Capybara.page.driver.browser.browser
        rescue
          browser = Selenium.page.driver.browser.browser
        rescue
          raise "Currently custom folders are only supported by Capybara"
          return nil
        end
        browser.to_s
      end

    end

  end
end
