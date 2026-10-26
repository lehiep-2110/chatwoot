<script>
import { createTypingIndicator } from '@chatwoot/utils';

const TYPING_INDICATOR_IDLE_TIME = 4000;
export default {
  props: {
    placeholder: {
      type: String,
      default: '',
    },
    modelValue: {
      type: String,
      default: '',
    },
    minHeight: {
      type: Number,
      default: 2,
    },
    rows: {
      type: Number,
      default: 2,
    },
  },
  emits: [
    'typingOn',
    'typingOff',
    'update:modelValue',
    'input',
    'blur',
    'focus',
  ],
  data() {
    return {
      typingIndicator: createTypingIndicator(
        () => {
          this.$emit('typingOn');
        },
        () => {
          this.$emit('typingOff');
        },
        TYPING_INDICATOR_IDLE_TIME
      ),
    };
  },
  watch: {
    modelValue() {
      this.resizeTextarea();
      // 🚨 watch triggers every time the value is changed, we cannot set this to focus then
      // when this runs, it sets the cursor to the end of the body, ignoring the signature
      // Suppose if someone manually set the cursor to the middle of the body
      // and starts typing, the cursor will be set to the end of the body
      // A surprise cursor jump? Definitely not user-friendly.
      if (document.activeElement !== this.$refs.textarea) {
        this.$nextTick(() => {
          this.setCursor();
        });
      }
    },
  },
  mounted() {
    this.$nextTick(() => {
      if (this.modelValue) {
        this.resizeTextarea();
        this.setCursor();
      } else {
        this.focus();
      }
    });
  },
  methods: {
    resizeTextarea() {
      this.$el.style.height = 'auto';
      if (!this.modelValue) {
        this.$el.style.height = `${this.minHeight}rem`;
      } else {
        this.$el.style.height = `${this.$el.scrollHeight}px`;
      }
    },
    setCursor() {
      const bodyEndsAt = this.modelValue.trimEnd().length;
      const textarea = this.$refs.textarea;

      if (textarea) {
        textarea.focus();
        textarea.setSelectionRange(bodyEndsAt, bodyEndsAt);
      }
    },
    onInput(event) {
      this.$emit('update:modelValue', event.target.value);
      this.$emit('input', event.target.value);
      this.resizeTextarea();
    },
    onKeyup() {
      this.typingIndicator.start();
    },
    onBlur() {
      this.typingIndicator.stop();
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
    focus() {
      if (this.$refs.textarea) this.$refs.textarea.focus();
    },
  },
};
</script>

<template>
  <textarea
    ref="textarea"
    :placeholder="placeholder"
    :rows="rows"
    :value="modelValue"
    @input="onInput"
    @focus="onFocus"
    @keyup="onKeyup"
    @blur="onBlur"
  />
</template>
