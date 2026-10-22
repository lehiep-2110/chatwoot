class Voice::CallTranscriptionJob < ApplicationJob
  queue_as :low

  # Keep queued legacy call jobs deserializable without contacting providers or changing history.
  def perform(_call_id); end
end
