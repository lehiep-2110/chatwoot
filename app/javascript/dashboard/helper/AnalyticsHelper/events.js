export const CONVERSATION_EVENTS = Object.freeze({
  SENT_MESSAGE: 'Sent a message',
  TRANSLATE_A_MESSAGE: 'Translated a message',
  INSERTED_A_VARIABLE: 'Inserted a variable',
  INSERTED_AN_EMOJI: 'Inserted an emoji',
  USED_MENTIONS: 'Used mentions',
  SEARCH_CONVERSATION: 'Searched conversations',
  APPLY_FILTER: 'Applied filters in the conversation list',
  CHANGE_PRIORITY: 'Assigned priority to a conversation',
});

export const ACCOUNT_EVENTS = Object.freeze({
  ADDED_A_CUSTOM_ATTRIBUTE: 'Added a custom attribute',
  ADDED_AN_INBOX: 'Added an inbox',
  OPEN_MESSAGE_CONTEXT_MENU: 'Opened message context menu',
});

export const LABEL_EVENTS = Object.freeze({
  CREATE: 'Created a label',
  UPDATE: 'Updated a label',
  DELETED: 'Deleted a label',
  APPLY_LABEL: 'Applied a label',
});

// CONTACTS PAGE EVENTS
export const CONTACTS_EVENTS = Object.freeze({
  APPLY_FILTER: 'Applied filters in the contacts list',
  SAVE_FILTER: 'Saved a filter in the contacts list',
  DELETE_FILTER: 'Deleted a filter in the contacts list',

  APPLY_SORT: 'Sorted contacts list',
  SEARCH: 'Searched contacts list',
  CREATE_CONTACT: 'Created a contact',
  MERGED_CONTACTS: 'Used merge contact option',
  IMPORT_MODAL_OPEN: 'Opened import contacts modal',
  IMPORT_FAILURE: 'Import contacts failed',
  IMPORT_SUCCESS: 'Imported contacts successfully',
});

export const SNOOZE_EVENTS = Object.freeze({
  NLP_SNOOZE_APPLIED: 'Applied snooze via text-to-date input',
});

export const GENERAL_EVENTS = Object.freeze({
  COMMAND_BAR: 'Used commandbar',
});

export const INBOX_EVENTS = Object.freeze({
  OPEN_CONVERSATION_VIA_INBOX: 'Opened conversation via inbox',
  MARK_NOTIFICATION_AS_READ: 'Marked notification as read',
  MARK_ALL_NOTIFICATIONS_AS_READ: 'Marked all notifications as read',
  MARK_NOTIFICATION_AS_UNREAD: 'Marked notification as unread',
  DELETE_NOTIFICATION: 'Deleted notification',
  DELETE_ALL_NOTIFICATIONS: 'Deleted all notifications',
});

export const LINEAR_EVENTS = Object.freeze({
  CREATE_ISSUE: 'Created a linear issue',
  LINK_ISSUE: 'Linked a linear issue',
  UNLINK_ISSUE: 'Unlinked a linear issue',
});

export const SESSION_EVENTS = Object.freeze({
  LIMIT_HIT: 'Session limit reached at login',
  REVOKED_FROM_PROFILE: 'Revoked an active session',
});

export const ONBOARDING_EVENTS = Object.freeze({
  ACCOUNT_DETAILS_VISITED: 'Onboarding: Account details visited',
  ACCOUNT_DETAILS_COMPLETED: 'Onboarding: Account details completed',
  INBOX_SETUP_VISITED: 'Onboarding: Inbox setup visited',
  INBOX_SETUP_COMPLETED: 'Onboarding: Inbox setup completed',
  INBOX_SETUP_SKIPPED: 'Onboarding: Inbox setup skipped',
});
