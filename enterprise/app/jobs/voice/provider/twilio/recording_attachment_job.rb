class Voice::Provider::Twilio::RecordingAttachmentJob < ApplicationJob
  queue_as :low

  # Keep queued legacy call jobs deserializable without contacting providers or changing history.
  def perform(_call_id, _recording_sid, _recording_url, _recording_duration = nil); end
end
