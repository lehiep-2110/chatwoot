import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import types from 'dashboard/store/mutation-types';

export function handleVoiceCallUpdated(commit, message) {
  if (message?.content_type !== CONTENT_TYPES.VOICE_CALL) return;

  const { provider_call_id: callSid, status: callStatus } = message.call || {};
  commit(types.UPDATE_MESSAGE_CALL_STATUS, {
    conversationId: message.conversation_id,
    callStatus,
    callSid,
  });
}
