<script setup>
import { computed } from 'vue';
import { CHAR_LENGTH_WARNING } from './constants';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  isReplyRestricted: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  isMessageLengthReachingThreshold: { type: Boolean, default: false },
  charactersRemaining: { type: Number, default: 0 },
});
defineEmits(['toggleEditorSize']);
const charLengthClass = computed(() =>
  props.charactersRemaining < 0 ? 'text-n-ruby-9' : 'text-n-slate-11'
);
const characterLengthWarning = computed(() =>
  props.charactersRemaining < 0
    ? `${-props.charactersRemaining} ${CHAR_LENGTH_WARNING.NEGATIVE}`
    : `${props.charactersRemaining} ${CHAR_LENGTH_WARNING.UNDER_50}`
);
</script>

<template>
  <div class="flex justify-between gap-2 h-[3.25rem] items-center ps-3 pe-2">
    <span
      class="text-sm"
      :class="{ 'opacity-50': disabled || isReplyRestricted }"
    >
      {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
    </span>
    <div class="flex items-center mx-4 my-0">
      <div
        v-if="isMessageLengthReachingThreshold"
        class="text-xs"
        :class="charLengthClass"
      >
        {{ characterLengthWarning }}
      </div>
    </div>
    <NextButton
      ghost
      class="text-n-slate-11"
      sm
      icon="i-lucide-maximize-2"
      @click="$emit('toggleEditorSize')"
    />
  </div>
</template>
