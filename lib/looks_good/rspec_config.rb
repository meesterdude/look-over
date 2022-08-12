require 'rspec'
RSpec.configure do |config|
config.before(:suite) do
    LooksGood.cleanup
  end
end