<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import FileUpload from 'vue-upload-component';
import * as ActiveStorage from 'activestorage';
import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import RequestContactInfoButton from '../RequestContactInfoButton.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  onSend: { type: Function, default: () => {} },
  sendButtonText: { type: String, default: '' },
  inbox: { type: Object, default: () => ({}) },
  showFileUpload: { type: Boolean, default: false },
  onFileUpload: { type: Function, default: () => {} },
  toggleEmojiPicker: { type: Function, default: () => {} },
  isSendDisabled: { type: Boolean, default: false },
  enableMultipleFileUpload: { type: Boolean, default: true },
  enableWhatsAppTemplates: { type: Boolean, default: false },
  enableContentTemplates: { type: Boolean, default: false },
  newConversationModalActive: { type: Boolean, default: false },
  conversationType: { type: String, default: '' },
  showQuotedReplyToggle: { type: Boolean, default: false },
  quotedReplyEnabled: { type: Boolean, default: false },
  isEditorDisabled: { type: Boolean, default: false },
});

defineEmits([
  'selectWhatsappTemplate',
  'selectContentTemplate',
  'toggleQuotedReply',
  'requestContactInfoTemplate',
]);

const { t } = useI18n();
const uploadRef = ref(false);
const showAttachButton = computed(
  () => !props.isEditorDisabled && props.showFileUpload
);
const allowedFileTypes = computed(() => {
  const channelType =
    props.conversationType === 'instagram_direct_message'
      ? INBOX_TYPES.INSTAGRAM
      : props.inbox.channel_type;
  return getAllowedFileTypesByChannel({
    channelType,
    medium: props.inbox.medium,
  });
});
const enableDragAndDrop = computed(() => !props.newConversationModalActive);
const quotedReplyToggleTooltip = computed(() =>
  props.quotedReplyEnabled
    ? t('CONVERSATION.REPLYBOX.QUOTED_REPLY.DISABLE_TOOLTIP')
    : t('CONVERSATION.REPLYBOX.QUOTED_REPLY.ENABLE_TOOLTIP')
);

useKeyboardEvents({
  '$mod+Alt+KeyA': {
    action: () => {
      if (props.isEditorDisabled) return;
      const uploadTriggerButton = document.querySelector(
        '#conversationAttachment'
      );
      if (uploadTriggerButton) uploadTriggerButton.click();
    },
    allowOnFocusedInput: true,
  },
});

onMounted(() => ActiveStorage.start());
</script>

<template>
  <div class="flex justify-between p-3">
    <div class="flex items-center gap-2">
      <NextButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        icon="i-ph-smiley-sticker"
        slate
        faded
        sm
        @click="toggleEmojiPicker"
      />
      <FileUpload
        v-if="showAttachButton"
        ref="uploadRef"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
        class="[&_label]:cursor-pointer [&:hover_button:enabled]:bg-n-slate-9/20"
        input-id="conversationAttachment"
        :size="4096 * 4096"
        :accept="allowedFileTypes"
        :multiple="enableMultipleFileUpload"
        :drop="enableDragAndDrop"
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        @input-file="onFileUpload"
      >
        <NextButton
          v-if="showAttachButton"
          v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          icon="i-ph-paperclip"
          slate
          faded
          sm
        />
      </FileUpload>
      <NextButton
        v-if="showQuotedReplyToggle"
        v-tooltip.top-end="quotedReplyToggleTooltip"
        icon="i-ph-quotes"
        :variant="quotedReplyEnabled ? 'solid' : 'faded'"
        color="slate"
        sm
        :aria-pressed="quotedReplyEnabled"
        @click="$emit('toggleQuotedReply')"
      />
      <NextButton
        v-if="enableWhatsAppTemplates"
        v-tooltip.top-end="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        icon="i-ph-whatsapp-logo"
        slate
        faded
        sm
        @click="$emit('selectWhatsappTemplate')"
      />
      <RequestContactInfoButton
        @request-template="$emit('requestContactInfoTemplate')"
      />
      <NextButton
        v-if="enableContentTemplates"
        v-tooltip.top-end="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        icon="i-ph-whatsapp-logo"
        slate
        faded
        sm
        @click="$emit('selectContentTemplate')"
      />
      <transition name="modal-fade">
        <div
          v-show="uploadRef && uploadRef.dropActive"
          class="flex fixed top-0 right-0 bottom-0 left-0 z-20 flex-col gap-2 justify-center items-center w-full h-full text-n-slate-12 bg-modal-backdrop-light dark:bg-modal-backdrop-dark"
        >
          <fluent-icon icon="cloud-backup" size="40" />
          <h4 class="text-2xl break-words text-n-slate-12">
            {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
    </div>
    <div class="flex">
      <NextButton
        :label="sendButtonText"
        type="submit"
        sm
        color="blue"
        :disabled="isSendDisabled"
        class="flex-shrink-0"
        @click="onSend"
      />
    </div>
  </div>
</template>
