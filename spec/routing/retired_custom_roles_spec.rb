require 'rails_helper'

RSpec.describe 'Retired custom role configuration APIs', type: :routing do
  %w[get post].each do |verb|
    it "does not route #{verb.upcase} to custom roles" do
      expect(verb.to_sym => '/api/v1/accounts/1/custom_roles').not_to be_routable
    end
  end

  %w[get put patch delete].each do |verb|
    it "does not route #{verb.upcase} to a custom role" do
      expect(verb.to_sym => '/api/v1/accounts/1/custom_roles/1').not_to be_routable
    end
  end
end
