require 'rails_helper'

RSpec.describe Channel::TwilioSms do
  it 'keeps legacy voice credentials without provisioning or tearing down calls on save' do
    expect(Twilio::REST::Client).not_to receive(:new)
    channel = create(:channel_twilio_sms, :with_voice, twiml_app_sid: nil)
    secret = channel.api_key_secret

    channel.update!(voice_enabled: false)
    channel.update!(voice_enabled: true)

    expect(channel.reload.api_key_secret).to eq(secret)
    expect(channel.twiml_app_sid).to be_nil
  end

  describe 'legacy call-only jobs' do
    let!(:call) { create(:call) }
    let(:arguments) do
      {
        'Voice::CallTranscriptionJob' => [call.id],
        'Voice::Provider::Twilio::RecordingAttachmentJob' => [call.id, 'RElegacy', 'https://retired.example.com/audio', 12]
      }
    end

    %w[Voice::CallTranscriptionJob Voice::Provider::Twilio::RecordingAttachmentJob].each do |name|
      it "consumes #{name} without network, new work or historical changes" do
        attributes = call.reload.attributes
        serialized = JSON.parse(name.constantize.new(*arguments.fetch(name)).serialize.to_json)
        expect(Twilio::REST::Client).not_to receive(:new)
        expect(HTTParty).not_to receive(:post)
        expect(Down).not_to receive(:download)

        expect do
          name.constantize.execute(serialized)
        end.not_to(change { [Call.count, Message.count, ActiveStorage::Attachment.count, enqueued_jobs.size] })

        expect(call.reload.attributes).to eq(attributes)
        expect(name.constantize.queue_name).to eq('low')
      end
    end
  end
end
