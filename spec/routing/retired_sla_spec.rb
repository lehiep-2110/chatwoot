require 'rails_helper'

RSpec.describe 'Retired SLA APIs', type: :routing do
  %w[get post].each do |verb|
    it "does not route #{verb.upcase} to SLA policies" do
      expect(verb.to_sym => '/api/v1/accounts/1/sla_policies').not_to be_routable
    end
  end

  %w[get put patch delete].each do |verb|
    it "does not route #{verb.upcase} to an SLA policy" do
      expect(verb.to_sym => '/api/v1/accounts/1/sla_policies/1').not_to be_routable
    end
  end

  ['', '/metrics', '/download'].each do |suffix|
    it "does not route applied SLA results#{suffix}" do
      expect(get: "/api/v1/accounts/1/applied_slas#{suffix}").not_to be_routable
    end
  end
end
