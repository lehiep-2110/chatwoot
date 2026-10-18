<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMessageContext } from '../provider.js';
import {
  VOICE_CALL_STATUS,
  VOICE_CALL_DIRECTION,
  VOICE_CALL_END_REASON,
  MESSAGE_TYPES,
  ATTACHMENT_TYPES,
} from '../constants';
import { formatDuration } from 'shared/helpers/timeHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';

const LABEL_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-phone-call-bold',
  [VOICE_CALL_STATUS.COMPLETED]: 'i-ph-phone-bold',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-phone-x-bold',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-phone-x-bold',
  [VOICE_CALL_STATUS.REJECTED]: 'i-ph-phone-x-bold',
};

const { t } = useI18n();
const store = useStore();
const { call, attachments, contentAttributes, conversationId, messageType } =
  useMessageContext();

const status = computed(() => call.value?.status);
// Server-side call records use `outgoing`/`incoming`, while the Pinia store
// and a few API hops normalise to `outbound`/`inbound`. Accept either so the
// bubble label matches the message orientation no matter the source.
const isOutbound = computed(() => {
  const dir = call.value?.direction;
  if (
    dir === VOICE_CALL_DIRECTION.OUTGOING ||
    dir === VOICE_CALL_DIRECTION.OUTBOUND
  )
    return true;
  if (
    dir === VOICE_CALL_DIRECTION.INCOMING ||
    dir === VOICE_CALL_DIRECTION.INBOUND
  )
    return false;
  // Fall back to the message orientation: agent-authored messages sit on the
  // right (outbound) and contact-authored ones on the left.
  return messageType.value === MESSAGE_TYPES.OUTGOING;
});
const isFailed = computed(() =>
  [
    VOICE_CALL_STATUS.NO_ANSWER,
    VOICE_CALL_STATUS.FAILED,
    VOICE_CALL_STATUS.REJECTED,
  ].includes(status.value)
);
const isMissedInbound = computed(() => isFailed.value && !isOutbound.value);
const endReason = computed(() => call.value?.endReason);
const wasDeclinedByAgent = computed(
  () =>
    isMissedInbound.value &&
    endReason.value === VOICE_CALL_END_REASON.AGENT_REJECTED
);
const acceptedByAgentId = computed(() => call.value?.acceptedByAgentId);
const conversationAssignee = computed(() => {
  const conversation = store.getters.getConversationById?.(
    conversationId?.value
  );
  return conversation?.meta?.assignee || null;
});
const displayAgentName = computed(() => {
  if (call.value?.acceptedByAgentName) return call.value.acceptedByAgentName;
  if (acceptedByAgentId.value) {
    const agent = store.getters['agents/getAgentById'](acceptedByAgentId.value);
    if (agent?.available_name) return agent.available_name;
    if (agent?.name) return agent.name;
  }
  return conversationAssignee.value?.name || null;
});

const audioAttachment = computed(() =>
  (attachments?.value || []).find(a => a.fileType === ATTACHMENT_TYPES.AUDIO)
);

const durationSeconds = computed(() => {
  const fromCall = call.value?.durationSeconds || call.value?.duration_seconds;
  if (fromCall != null) return fromCall;
  const data = contentAttributes?.value?.data;
  return data?.durationSeconds || data?.duration_seconds;
});

const formattedDuration = computed(() => formatDuration(durationSeconds.value));

// Agent who handled the call (initiator on outbound, answerer on inbound), taken
// strictly from the persisted accept fields — never the conversation's current
// assignee, which would mis-attribute a historical call after a reassignment.
const handlerName = computed(() => {
  if (call.value?.acceptedByAgentName) return call.value.acceptedByAgentName;
  if (!acceptedByAgentId.value) return null;
  const agent = store.getters['agents/getAgentById'](acceptedByAgentId.value);
  return agent?.available_name || agent?.name || null;
});

const handledBy = computed(() =>
  handlerName.value
    ? t('CONVERSATION.VOICE_CALL.HANDLED_BY', { agentName: handlerName.value })
    : null
);

const labelKey = computed(() => {
  if (LABEL_MAP[status.value]) return LABEL_MAP[status.value];
  if (isFailed.value) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.NO_ANSWER_OUTBOUND_LABEL'
      : 'CONVERSATION.VOICE_CALL.MISSED_CALL';
  }
  // RINGING or an as-yet-unknown/initial status: orient purely by direction so an
  // outbound call never falls through to the "Incoming call" label.
  return isOutbound.value
    ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
    : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
});

const subtext = computed(() => {
  // Completed: "Handled by {agent} · 0:42" (drops either part when absent).
  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return [handledBy.value, formattedDuration.value]
      .filter(Boolean)
      .join(' · ');
  }
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return handledBy.value;
  }
  if (isFailed.value) {
    // Missed/failed calls have no handler, so keep the reason rather than "Handled by".
    if (isOutbound.value) {
      return t('CONVERSATION.VOICE_CALL.NO_ANSWER_OUTBOUND_SUBTEXT');
    }
    if (wasDeclinedByAgent.value && displayAgentName.value) {
      return t('CONVERSATION.VOICE_CALL.MISSED_CALL_DECLINED_BY', {
        agentName: displayAgentName.value,
      });
    }
    return t('CONVERSATION.VOICE_CALL.MISSED_CALL_INBOUND_SUBTEXT');
  }
  // RINGING or an as-yet-unknown/initial status.
  if (isOutbound.value) {
    return handledBy.value || t('CONVERSATION.VOICE_CALL.CALLING');
  }
  return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
});

const iconName = computed(() => {
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value
    ? 'i-ph-phone-outgoing-bold'
    : 'i-ph-phone-incoming-bold';
});

// Subtle icon container — matches the design's tonal swatch over the bubble bg.
// Status drives the accent: teal for live, ruby for missed, neutral otherwise.
const iconContainerClass = computed(() => {
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return 'bg-n-teal-3 text-n-teal-11';
  }
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return 'bg-n-teal-3 text-n-teal-11';
  }
  if (isMissedInbound.value) {
    return 'bg-n-alpha-2 text-n-ruby-9';
  }
  return 'bg-n-alpha-2 text-n-slate-12';
});

const recordingAttachment = computed(() => {
  if (audioAttachment.value) return audioAttachment.value;
  const url = call.value?.recordingUrl;
  if (!url) return null;
  return {
    dataUrl: url,
    fileType: ATTACHMENT_TYPES.AUDIO,
    extension: 'wav',
    transcribedText: call.value?.transcript || '',
  };
});
</script>

<template>
  <BaseBubble class="!p-3 !max-w-md min-w-[240px]" hide-meta>
    <div class="flex flex-col gap-3 w-full">
      <!-- Header row: icon + title + duration/subtext -->
      <div class="flex gap-2.5 items-start">
        <div
          class="flex justify-center items-center rounded-xl size-11 shrink-0"
          :class="iconContainerClass"
        >
          <Icon class="size-4" :icon="iconName" />
        </div>
        <div class="flex flex-col flex-1 min-w-0 self-center">
          <span
            class="font-display text-sm font-medium leading-tight truncate tracking-tight"
          >
            {{ $t(labelKey) }}
          </span>
          <span
            v-if="subtext"
            class="text-sm leading-tight truncate tracking-tight opacity-75"
          >
            {{ subtext }}
          </span>
        </div>
      </div>

      <!-- Audio player (when there's a recording) -->
      <AudioChip
        v-if="recordingAttachment"
        :attachment="recordingAttachment"
        show-transcribed-text
      />
    </div>
  </BaseBubble>
</template>
