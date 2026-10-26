class CustomExceptions::VoiceMessagesDisabled < StandardError
  def initialize
    super(I18n.t('errors.voice_messages_disabled'))
  end
end
