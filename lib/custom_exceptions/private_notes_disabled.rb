class CustomExceptions::PrivateNotesDisabled < StandardError
  def initialize
    super(I18n.t('errors.private_notes_disabled'))
  end
end
