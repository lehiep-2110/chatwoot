class CustomExceptions::MessageSignaturesDisabled < StandardError
  def initialize
    super(I18n.t('errors.message_signatures_disabled'))
  end
end
