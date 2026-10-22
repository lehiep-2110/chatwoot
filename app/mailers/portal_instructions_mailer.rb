class PortalInstructionsMailer < ApplicationMailer
  # Consume previously queued deliveries without sending retired Help Center instructions.
  def send_cname_instructions(**); end
end
