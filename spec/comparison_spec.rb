require 'spec_helper'

describe LooksGood::Comparison do

  before do
    apple = Magick::Image.new(100,100) { self.background_color = "green" }
    orange = Magick::Image.new(100,100) { self.background_color = "orange" }
    @apple = LooksGood::Image.new(apple, "apple.png")
    @orange = LooksGood::Image.new(orange, "orange.png")
  end

  describe 'will compare two images' do

    it 'will return true if the images are identical' do
      LooksGood::Comparison.new(@apple, @apple).matches?.should == true
    end

    it 'will return false if the images are different' do
      LooksGood::Comparison.new(@orange, @apple).matches?.should == false
    end
  end

  describe 'Diff images' do
    describe 'for two images with the same size' do
      it 'will be generated' do
        LooksGood::Comparison.new(@apple, @orange).diff_image.class.should == LooksGood::Image
      end
    end

    describe 'for two images with different sizes' do
      before do
        @apple_image = Magick::Image.new(30,300) { self.background_color = "green" }
        @orange_image = Magick::Image.new(80,100) { self.background_color = "orange" }

        @apple = LooksGood::Image.new(@apple_image, "apple.png")
        @orange = LooksGood::Image.new(@orange_image, "orange.png")

        @diff_image = LooksGood::Comparison.new(@apple, @orange).diff_image
      end

      it 'will be generated' do
        @diff_image.class.should == LooksGood::Image
      end

      it 'will be extended to cover the difference in both images' do
        @diff_image.image.columns.should eql 80
        @diff_image.image.rows.should eql 300
      end

      describe 'with two different offset' do
        before do
          @apple_image.offset = 50
          @orange_image.offset = 2

          @diff_image = LooksGood::Comparison.new(@apple, @orange).diff_image
        end

        it 'will remove image offset from the diff image' do
          @diff_image.image.offset.should eql 0
        end

      end

    end
  end
end
