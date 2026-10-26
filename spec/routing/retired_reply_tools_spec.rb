require 'rails_helper'

RSpec.describe 'Retired reply tools', type: :routing do
  %w[get post].each do |verb|
    it "does not route #{verb.upcase} to the canned response collection" do
      expect(verb.to_sym => '/api/v1/accounts/1/canned_responses').not_to be_routable
    end
  end

  %w[put patch delete].each do |verb|
    it "does not route #{verb.upcase} to a canned response" do
      expect(verb.to_sym => '/api/v1/accounts/1/canned_responses/1').not_to be_routable
    end
  end

  %w[get post].each do |verb|
    it "does not route #{verb.upcase} to the macro collection" do
      expect(verb.to_sym => '/api/v1/accounts/1/macros').not_to be_routable
    end
  end

  %w[get put patch delete].each do |verb|
    it "does not route #{verb.upcase} to a macro" do
      expect(verb.to_sym => '/api/v1/accounts/1/macros/1').not_to be_routable
    end
  end

  it 'does not route macro execution' do
    expect(post: '/api/v1/accounts/1/macros/1/execute').not_to be_routable
  end
end
