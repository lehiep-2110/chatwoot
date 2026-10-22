module Enterprise::Channel::TwilioSms
  extend ActiveSupport::Concern
  include Concerns::CallRecordingSettings

  def self.prepended(base)
    base.class_eval do
      encrypts :api_key_secret if Chatwoot.encryption_configured?
    end
  end

  # Preserve credentials used by messaging on inboxes created before Calls retirement.
  def client
    if api_key_sid.present? && api_key_secret.present?
      Twilio::REST::Client.new(api_key_sid, api_key_secret, account_sid)
    else
      super
    end
  end
end
