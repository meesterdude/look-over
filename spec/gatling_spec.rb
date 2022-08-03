require 'spec_helper'
include Capybara::DSL

describe LooksGood do

  after :all do
    config_clean_up
  end

  let(:actual_image)      { mock("LooksGood::Image") }
  let(:expected_image)    { mock("LooksGood::Image") }
  let(:comparison)        { mock("LooksGood::Comparison") }
  let(:element)           { mock("LooksGood::CaptureElement") }

  
  describe 'comparison' do
    before :each do
      LooksGood::ImageFromFile.stub!(:new).and_return(expected_image)
      LooksGood::ImageFromElement.stub!(:new).and_return(actual_image)
      LooksGood::Comparison.stub!(:new).and_return(comparison)
      expected_image.should_receive(:file_name).and_return('expected_image.png')
    end

    it 'will return true if the images are identical' do
        comparison.stub!(:matches?).and_return(true)
        File.stub!(:exists?).and_return(true)

        subject.matches?("expected_image.png", @element).should be_true
    end
  end  


  describe 'saving images' do
    before :each do
      @image_class_mock = mock(LooksGood::Image)
    end


    it "#save_image_as_diff" do
      @image_class_mock.should_receive(:save).with(:diff).and_return(@ref_path)
      @image_class_mock.should_receive(:file_name).at_least(:once).and_return("some_name")

      expect {subject.save_image_as_diff(@image_class_mock)}.to raise_error
    end

    it "#save_image_as_candidate" do
      @image_class_mock.should_receive(:save).with(:candidate).and_return(@ref_path)
      @image_class_mock.should_receive(:file_name).at_least(:once).and_return("some_name")
      @image_class_mock.should_receive(:path).and_return(@path)
      expect {subject.save_image_as_candidate(@image_class_mock)}.to raise_error
    end

    describe "#save_image_as_reference" do

      let(:image) {mock('image.png')}
      let(:reference_image) {LooksGood::ImageFromElement.stub(:new).and_return(image)}
      let(:comparison) {mock("comparison")}

      before :each do
        LooksGood.stub!(:compare_until_match).and_return(comparison)
      end

    end
  end  

  describe "#compare_until_match" do

    before :each do
      LooksGood::ImageFromElement.stub!(:new).and_return(actual_image)
      LooksGood::ImageFromFile.stub!(:new).and_return(expected_image)
      LooksGood::Comparison.stub!(:new).and_return(comparison)

      expected_image.should_receive(:file_name).at_least(:once).and_return('expected_image.png')
    end

    it "should try match for a specified amount of times" do
      comparison.should_receive(:matches?).exactly(3).times.and_return(false)
      LooksGood.compare_until_match(@element, expected_image, 3, 0.1)
    end

    it "should pass after a few tries if match is found" do
      comparison.should_receive(:matches?).exactly(1).times.and_return(true)
      LooksGood.compare_until_match(@element, expected_image, 3, 0.1)
    end

  end
end