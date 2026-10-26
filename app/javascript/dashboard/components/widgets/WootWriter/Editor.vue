<script setup>
// TODO This is a huge component, we should split this up into separate composables
import {
  ref,
  unref,
  computed,
  watch,
  onMounted,
  useTemplateRef,
  nextTick,
} from 'vue';

import KeyboardEmojiSelector from './keyboardEmojiSelector.vue';
import TagAgents from '../conversation/TagAgents.vue';
import VariableList from '../conversation/VariableList.vue';

import { useEmitter } from 'dashboard/composables/emitter';
import { useI18n } from 'vue-i18n';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import {
  messageSchema,
  buildMessageSchema,
  buildEditor,
  EditorView,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
  EditorState,
  Selection,
  imageResizeView,
} from '@chatwoot/prosemirror-schema';
import {
  suggestionsPlugin,
  triggerCharacters,
} from '@chatwoot/prosemirror-schema/src/mentions/plugin';

import {
  collapseSelection,
  findNodeToInsertImage,
  getContentNode,
  insertAtCursor,
  scrollCursorIntoView,
  getFormattingForEditor,
  getSelectionCoords,
  calculateMenuPosition,
  getEffectiveChannelType,
  stripUnsupportedFormatting,
  createVariableInputRule,
} from 'dashboard/helper/editorHelper';
import {
  hasPressedEnterAndNotCmdOrShift,
  hasPressedCommandAndEnter,
  isEscape,
} from 'shared/helpers/KeyboardHelpers';
import { createTypingIndicator } from '@chatwoot/utils';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorId: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  isPrivate: { type: Boolean, default: false },
  enableSuggestions: { type: Boolean, default: true },
  overrideLineBreaks: { type: Boolean, default: false },
  updateSelectionWith: { type: String, default: '' },
  enableVariables: { type: Boolean, default: false },
  variables: { type: Object, default: () => ({}) },
  channelType: { type: String, default: '' },
  medium: { type: String, default: '' },
  focusOnMount: { type: Boolean, default: true },
  // Global INSERT_INTO_RICH_EDITOR bus events are meant for the conversation
  // reply editor only — other mounted
  // other editors must not consume them.
  enableInsertEvents: { type: Boolean, default: false },
});

const emit = defineEmits([
  'typingOn',
  'typingOff',
  'toggleUserMention',
  'toggleVariablesMenu',
  'clearSelection',
  'blur',
  'focus',
  'input',
  'update:modelValue',
]);

const { t } = useI18n();

const TYPING_INDICATOR_IDLE_TIME = 4000;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB
const DEFAULT_FORMATTING = 'Context::Default';
const PRIVATE_NOTE_FORMATTING = 'Context::PrivateNote';
const INLINE_IMAGE_PASTE_TYPES = [
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/gif',
  'image/webp',
];

const effectiveChannelType = computed(() =>
  getEffectiveChannelType(props.channelType, props.medium)
);

const editorSchema = computed(() => {
  if (!props.channelType) return messageSchema;

  const formatType = props.isPrivate
    ? PRIVATE_NOTE_FORMATTING
    : effectiveChannelType.value;
  const formatting = getFormattingForEditor(formatType);
  return buildMessageSchema(formatting.marks, formatting.nodes);
});

const editorMenuOptions = computed(() => {
  const formatType = props.isPrivate
    ? PRIVATE_NOTE_FORMATTING
    : effectiveChannelType.value || DEFAULT_FORMATTING;
  const formatting = getFormattingForEditor(formatType);

  return formatting.menu;
});

const createState = (content, placeholder, plugins = [], methods = {}) => {
  const schema = editorSchema.value;
  // Strip unsupported formatting before parsing to prevent "Token type not supported" errors
  const sanitizedContent = stripUnsupportedFormatting(content, schema);
  return EditorState.create({
    doc: new MessageMarkdownTransformer(schema).parse(sanitizedContent),
    plugins: buildEditor({
      schema,
      placeholder,
      methods,
      plugins,
      enabledMenuOptions: editorMenuOptions.value,
    }),
  });
};

const { isEditorHotKeyEnabled } = useUISettings();

const typingIndicator = createTypingIndicator(
  () => emit('typingOn'),
  () => emit('typingOff'),
  TYPING_INDICATOR_IDLE_TIME
);

// we don't need them to be reactive
// It cases weird issues where the objects are proxied
// and then the editor doesn't work as expected
// We have to wrap them in closures or use toRaw to get the actual values
let editorView = null;
let state = null;

const showUserMentions = ref(false);
const showVariables = ref(false);
const showEmojiMenu = ref(false);
const mentionSearchKey = ref('');
const variableSearchKey = ref('');
const emojiSearchKey = ref('');
const range = ref(null);
const isTextSelected = ref(false); // Tracks text selection and prevents unnecessary re-renders on mouse selection

// element ref
const editorRoot = useTemplateRef('editorRoot');
const imageUpload = useTemplateRef('imageUpload');
const editor = useTemplateRef('editor');

// Anchors the picker to the trigger character, since editors can be much taller than the
// line being typed on. Offsets are relative to the editor so the picker can sit on that
// line and track it from there.
const caretPosition = computed(() => {
  if (!editorView || !range.value || !editorRoot.value) return null;
  const from = Math.min(range.value.from, editorView.state.doc.content.size);
  const { top, bottom } = editorView.coordsAtPos(from);
  const editorTop = editorRoot.value.getBoundingClientRect().top;
  return { top: top - editorTop, height: bottom - top };
});

const isEditorMenuPopover = computed(
  () =>
    editorRoot.value?.classList.contains('popover-prosemirror-menu') ?? false
);

const contentFromEditor = () => {
  return MessageMarkdownSerializer.serialize(editorView.state.doc);
};

const shouldShowVariables = computed(() => {
  return props.enableVariables && showVariables.value && !props.isPrivate;
});

const shouldShowUserMentions = computed(() => {
  return showUserMentions.value && props.isPrivate;
});

// The picker owns the search field, so it takes focus while open. Dismissing it hands
// focus back; selecting one does so through the insert itself. The suggestion stays
// active in the document, so the picker only reopens once the trigger is typed afresh.
const dismissPicker = showMenu => {
  showMenu.value = false;
  editorView?.focus();
};

const dismissUserMentions = () => dismissPicker(showUserMentions);
const dismissVariables = () => dismissPicker(showVariables);
const dismissEmojiMenu = () => dismissPicker(showEmojiMenu);

// Deleting the trigger drops the suggestion, so the plugin closes the picker through
// `onExit` on its own.
const removeSuggestionTrigger = () => {
  if (!editorView || !range.value) return;
  const { from, to } = range.value;
  const end = Math.min(to, editorView.state.doc.content.size);
  editorView.dispatch(editorView.state.tr.delete(from, end));
  editorView.focus();
};

function createSuggestionPlugin({
  trigger,
  minChars = 0,
  showMenu,
  searchTerm,
  isAllowed = () => true,
}) {
  return suggestionsPlugin({
    matcher: triggerCharacters(trigger, minChars),
    suggestionClass: '',
    onEnter: args => {
      if (!isAllowed()) return false;
      range.value = args.range;
      editorView = args.view;
      if (searchTerm) searchTerm.value = args.text || '';
      showMenu.value = true;
      return false;
    },
    onChange: args => {
      editorView = args.view;
      range.value = args.range;
      if (searchTerm) searchTerm.value = args.text;
      return false;
    },
    onExit: () => {
      if (searchTerm) searchTerm.value = '';
      showMenu.value = false;
      return false;
    },
  });
}

const plugins = computed(() => {
  if (!props.enableSuggestions) {
    return [];
  }

  return [
    createSuggestionPlugin({
      trigger: '@',
      showMenu: showUserMentions,
      searchTerm: mentionSearchKey,
    }),
    createSuggestionPlugin({
      trigger: '{{',
      showMenu: showVariables,
      searchTerm: variableSearchKey,
      isAllowed: () => !props.isPrivate,
    }),
    createVariableInputRule({
      isPrivate: () => props.isPrivate,
      getVariables: () => props.variables,
    }),
    createSuggestionPlugin({
      trigger: ':',
      minChars: 2,
      showMenu: showEmojiMenu,
      searchTerm: emojiSearchKey,
    }),
  ];
});

watch(shouldShowUserMentions, updatedValue => {
  emit('toggleUserMention', updatedValue);
});
watch(shouldShowVariables, updatedValue => {
  emit('toggleVariablesMenu', updatedValue);
});
function focusEditorInputField(pos = 'end') {
  const { tr } = editorView.state;

  const selection =
    pos === 'end' ? Selection.atEnd(tr.doc) : Selection.atStart(tr.doc);

  editorView.dispatch(tr.setSelection(selection));
  editorView.focus();
}

function focusEditor() {
  if (!props.disabled && props.focusOnMount) focusEditorInputField('end');
}

function openFileBrowser() {
  imageUpload.value.click();
}

function reloadState(content = props.modelValue) {
  range.value = null;
  showUserMentions.value = false;
  showVariables.value = false;
  showEmojiMenu.value = false;

  const unrefContent = unref(content);
  state = createState(
    unrefContent,
    props.placeholder,
    plugins.value,
    { onImageUpload: openFileBrowser },
    editorMenuOptions.value
  );

  editorView.updateState(state);
  focusEditor();
}

function setMenubarPosition({ selection } = {}) {
  const wrapper = editorRoot.value;
  if (!selection || !wrapper) return;
  if (!isEditorMenuPopover.value) return;

  const rect = wrapper.getBoundingClientRect();
  const isRtl = getComputedStyle(wrapper).direction === 'rtl';

  // Calculate coords and final position
  const coords = getSelectionCoords(editorView, selection, rect);
  const { left, top, width } = calculateMenuPosition(coords, rect, isRtl);

  wrapper.style.setProperty('--selection-left', `${left}px`);
  wrapper.style.setProperty(
    '--selection-right',
    `${rect.width - left - width}px`
  );
  wrapper.style.setProperty('--selection-top', `${top}px`);
}

function checkSelection(editorState) {
  const { selection } = editorState;
  // Skip NodeSelection (from Esc -> selectParentNode); only text ranges count.
  const hasSelection = !selection.empty && !selection.node;
  if (hasSelection === isTextSelected.value) return;

  isTextSelected.value = hasSelection;
  const wrapper = editorRoot.value;
  if (!wrapper) return;

  wrapper.classList.toggle('has-selection', hasSelection);
  if (hasSelection) setMenubarPosition(editorState);
}

function emitOnChange() {
  emit('input', contentFromEditor());
  emit('update:modelValue', contentFromEditor());
}

function isEnterToSendEnabled() {
  return isEditorHotKeyEnabled('enter');
}

function isCmdPlusEnterToSendEnabled() {
  return isEditorHotKeyEnabled('cmd_enter');
}

function onImageInsertInEditor(fileUrl) {
  const { tr } = editorView.state;

  const insertData = findNodeToInsertImage(editorView.state, fileUrl);

  if (insertData) {
    editorView.dispatch(
      tr.insert(insertData.pos, insertData.node).scrollIntoView()
    );
    focusEditorInputField();
  }
}

async function uploadImageToStorage(file) {
  try {
    const { fileUrl } = await uploadFile(file);
    if (fileUrl) {
      onImageInsertInEditor(fileUrl);
    }
    useAlert(t('CONVERSATION.REPLYBOX.IMAGE_UPLOAD_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.REPLYBOX.IMAGE_UPLOAD_ERROR'));
  }
}

function uploadImageIfWithinSizeLimit(file) {
  if (!file) return;
  if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    uploadImageToStorage(file);
  } else {
    useAlert(
      t(
        'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR',
        {
          size: MAXIMUM_FILE_UPLOAD_SIZE,
        }
      )
    );
  }
}

function onFileChange() {
  const input = imageUpload.value;
  uploadImageIfWithinSizeLimit(input.files[0]);
  input.value = '';
}

const allowsInlineImagePaste = computed(
  () =>
    !props.isPrivate &&
    (props.channelType === INBOX_TYPES.EMAIL ||
      props.channelType === INBOX_TYPES.WEB)
);

// Shift+Cmd/Ctrl+V on email/website: upload a clipboard image inline. This
// gesture's native paste event carries no image, so clipboard.read() is the
// only way to get the bytes. No preventDefault: text still pastes natively.
async function pasteInlineImageFromClipboard() {
  if (!editorView?.hasFocus()) return;
  if (!allowsInlineImagePaste.value || !navigator.clipboard?.read) return;
  try {
    const items = await navigator.clipboard.read();
    const imageItem = items.find(item =>
      item.types.some(type => INLINE_IMAGE_PASTE_TYPES.includes(type))
    );
    if (!imageItem) return;
    const imageType = imageItem.types.find(type =>
      INLINE_IMAGE_PASTE_TYPES.includes(type)
    );
    const blob = await imageItem.getType(imageType);
    uploadImageIfWithinSizeLimit(
      new File([blob], 'pasted-image', { type: imageType })
    );
  } catch (error) {
    // clipboard-read denied/unfocused (NotAllowedError): image can't be read.
    // Text paste is unaffected — ProseMirror handles it from the native event.
  }
}

useKeyboardEvents({
  'Alt+KeyL': {
    action: focusEditorInputField,
    allowOnFocusedInput: false,
  },
  '$mod+Shift+KeyV': {
    action: pasteInlineImageFromClipboard,
    allowOnFocusedInput: true,
  },
});

function handleLineBreakWhenEnterToSendEnabled(event) {
  if (
    hasPressedEnterAndNotCmdOrShift(event) &&
    isEnterToSendEnabled() &&
    !props.overrideLineBreaks
  ) {
    event.preventDefault();
  }
}

async function insertNodeIntoEditor(node, from = 0, to = 0) {
  state = insertAtCursor(editorView, node, from, to);
  emitOnChange();
  await nextTick();
  scrollCursorIntoView(editorView);
}

function insertContentIntoEditor(content, defaultFrom = 0) {
  const from = defaultFrom || editorView.state.selection.from || 0;
  // Use the editor's current schema to ensure compatibility with buildMessageSchema
  const currentSchema = editorView.state.schema;
  // Strip unsupported formatting before parsing to ensure content can be inserted
  // into channels that don't support certain markdown features (e.g., API channels)
  const sanitizedContent = stripUnsupportedFormatting(content, currentSchema);
  let node = new MessageMarkdownTransformer(currentSchema).parse(
    sanitizedContent
  );

  insertNodeIntoEditor(node, from, undefined);
}

/**
 * Inserts special content (mention, variable, emoji) into the editor.
 * @param {string} type - The type of special content to insert. Possible values: 'mention', 'variable', 'emoji'.
 * @param {Object|string} content - The content to insert, depending on the type.
 */
function insertSpecialContent(type, content) {
  if (!editorView) {
    return;
  }

  let { node, from, to } = getContentNode(
    editorView,
    type,
    content,
    range.value,
    props.variables
  );

  if (!node) return;

  insertNodeIntoEditor(node, from, to);

  const event_map = {
    mention: CONVERSATION_EVENTS.USED_MENTIONS,
    variable: CONVERSATION_EVENTS.INSERTED_A_VARIABLE,
    emoji: CONVERSATION_EVENTS.INSERTED_AN_EMOJI,
  };

  useTrack(event_map[type]);
}

function handleLineBreakWhenCmdAndEnterToSendEnabled(event) {
  if (
    hasPressedCommandAndEnter(event) &&
    isCmdPlusEnterToSendEnabled() &&
    !props.overrideLineBreaks
  ) {
    event.preventDefault();
  }
}

function onKeydown(event) {
  if (isEscape(event)) {
    collapseSelection(editorView);
    return true;
  }
  if (isEnterToSendEnabled()) {
    handleLineBreakWhenEnterToSendEnabled(event);
  }
  if (isCmdPlusEnterToSendEnabled()) {
    handleLineBreakWhenCmdAndEnterToSendEnabled(event);
  }
  return false;
}

function createEditorView() {
  editorView = new EditorView(editor.value, {
    state: state,
    editable: () => !props.disabled,
    attributes: { class: 'resizable-editor-body' },
    nodeViews: {
      image: imageResizeView,
    },
    dispatchTransaction: tx => {
      state = state.apply(tx);
      editorView.updateState(state);
      if (tx.docChanged) {
        emitOnChange();
      }
      checkSelection(state);
    },
    handleDOMEvents: {
      keyup: () => {
        if (!props.disabled) {
          typingIndicator.start();
        }
      },
      keydown: (view, event) => !props.disabled && onKeydown(event),
      focus: () => !props.disabled && emit('focus'),
      blur: () => {
        if (props.disabled) return;
        typingIndicator.stop();
        // PM keeps its selection on blur — clear the menu flags manually.
        isTextSelected.value = false;
        editorRoot.value?.classList.remove('has-selection');
        emit('blur');
      },
      paste: (view, event) => {
        if (props.disabled) return;
        const { files } = event.clipboardData;
        if (!files.length) return;
        event.preventDefault();
        // Paste text content alongside files (e.g., spreadsheet data from Numbers app)
        // Numbers app includes invalid 0-byte attachments with text, so we paste the text here
        // while ReplyBox filters and handles valid file attachments
        const text = event.clipboardData.getData('text/plain');
        if (text) {
          view.dispatch(view.state.tr.insertText(text));
          emitOnChange();
        }
      },
    },
  });
}

watch(
  computed(() => props.modelValue),
  (newVal = '') => {
    if (newVal !== contentFromEditor()) {
      reloadState(newVal);
    }
  }
);

watch(
  computed(() => props.editorId),
  () => {
    reloadState(props.modelValue);
  }
);

watch(
  computed(() => props.isPrivate),
  () => {
    reloadState(props.modelValue);
  }
);

watch(
  computed(() => props.disabled),
  () => editorView?.setProps({})
);

watch(
  computed(() => props.updateSelectionWith),
  (newValue, oldValue) => {
    if (!editorView) return;

    if (newValue !== oldValue) {
      if (props.updateSelectionWith !== '') {
        const node = editorView.state.schema.text(props.updateSelectionWith);

        const tr = editorView.state.tr.replaceSelectionWith(node);
        editorView.focus();
        state = editorView.state.apply(tr);
        editorView.updateState(state);
        emitOnChange();
        emit('clearSelection');
      }
    }
  }
);

onMounted(() => {
  // [VITE] state assignment was done in created before
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    { onImageUpload: openFileBrowser },
    editorMenuOptions.value
  );

  createEditorView();
  editorView.updateState(state);
  if (props.focusOnMount) {
    focusEditorInputField();
  }
});

defineExpose({ focusEditorInputField });

// BUS Event to insert text or markdown into the editor at the
// current cursor position.
// Components using this
// 1. SearchPopover.vue
useEmitter(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, content => {
  if (!props.enableInsertEvents) return;
  insertContentIntoEditor(content);
});
</script>

<template>
  <div
    ref="editorRoot"
    class="relative w-full"
    :class="{
      'opacity-50 cursor-not-allowed pointer-events-none': disabled,
    }"
  >
    <TagAgents
      v-if="shouldShowUserMentions"
      :caret-position="caretPosition"
      :search-key="mentionSearchKey"
      @close="dismissUserMentions"
      @remove-trigger="removeSuggestionTrigger"
      @select-agent="content => insertSpecialContent('mention', content)"
    />
    <VariableList
      v-if="shouldShowVariables"
      :caret-position="caretPosition"
      :search-key="variableSearchKey"
      :variables="variables"
      @close="dismissVariables"
      @remove-trigger="removeSuggestionTrigger"
      @select-variable="content => insertSpecialContent('variable', content)"
    />
    <KeyboardEmojiSelector
      v-if="showEmojiMenu"
      :caret-position="caretPosition"
      :search-key="emojiSearchKey"
      @close="dismissEmojiMenu"
      @remove-trigger="removeSuggestionTrigger"
      @select-emoji="emoji => insertSpecialContent('emoji', emoji)"
    />
    <input
      ref="imageUpload"
      type="file"
      accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
      hidden
      @change="onFileChange"
    />
    <div ref="editor" />
    <slot name="footer" />
  </div>
</template>

<style lang="scss">
@import '@chatwoot/prosemirror-schema/src/styles/base.scss';

.ProseMirror-menubar-wrapper {
  @apply flex flex-col gap-3;

  .ProseMirror-menubar {
    min-height: 1.25rem !important;
    @apply items-center gap-4 flex pb-0 bg-transparent text-n-slate-11 relative ltr:-left-[3px] rtl:-right-[3px];

    .ProseMirror-menu-active {
      @apply bg-n-slate-5 dark:bg-n-solid-3 !important;
    }

    .ProseMirror-menuitem {
      @apply mr-0 size-4 flex items-center justify-center;

      .ProseMirror-icon {
        @apply size-4 flex items-center justify-center flex-shrink-0;

        svg {
          @apply size-full;
        }
      }
    }
  }

  .ProseMirror-menubar:not(:has(*)) {
    max-height: none !important;
    min-height: 0 !important;
    padding: 0 !important;
    display: none !important;
  }

  > .ProseMirror {
    @apply p-0 break-words text-n-slate-12;

    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p {
      @apply text-n-slate-12;
    }

    blockquote {
      @apply border-n-slate-7;

      p {
        @apply text-n-slate-11;
      }
    }
  }
}

.ProseMirror-woot-style {
  @apply overflow-auto;
}

.ProseMirror-woot-style:not(
    :where(.resizable-editor-wrapper .resizable-editor-body)
  ) {
  @apply min-h-[5rem] max-h-[7.5rem];
}

.ProseMirror-prompt-backdrop::backdrop {
  @apply bg-n-alpha-black1 backdrop-blur-[4px];
}

.ProseMirror-prompt {
  @apply bg-n-alpha-3 border border-n-strong p-6 shadow-xl rounded-xl w-96 !important;

  h5 {
    @apply text-n-slate-12 mb-3;
  }

  .ProseMirror-prompt-buttons {
    button {
      @apply h-8 px-3;

      &[type='submit'] {
        @apply bg-n-brand text-white hover:bg-n-brand/90;
      }

      &[type='button'] {
        @apply bg-n-slate-9/10 text-n-slate-12 hover:bg-n-slate-9/20;
      }
    }
  }
}

.is-private {
  .prosemirror-mention-node {
    @apply font-medium bg-n-amber-2/80 dark:bg-n-amber-2/80 text-n-slate-12 py-0 px-1;
  }

  .ProseMirror-menubar-wrapper {
    > .ProseMirror {
      @apply text-n-slate-12;

      p {
        @apply text-n-slate-12;
      }
    }
  }
}

.prosemirror-tools-node {
  @apply font-medium text-n-slate-12 py-0;
}

.editor-wrap {
  @apply mb-4;
}

.message-editor {
  @apply rounded-lg outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 bg-n-alpha-black2 py-0 px-1 mb-0;
}

.editor_warning {
  @apply outline outline-1 outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9;
}

.editor-warning__message {
  @apply text-n-ruby-9 dark:text-n-ruby-9 font-normal text-sm pt-1 pb-0 px-0;
}

// Float editor menu
.popover-prosemirror-menu {
  position: relative;

  .ProseMirror p:last-child {
    margin-bottom: 10px !important;
  }

  .ProseMirror-menubar {
    display: none; // Hide by default
  }

  &.has-selection {
    // Hide menu completely when it has no items
    .ProseMirror-menubar:not(:has(*)) {
      display: none !important;
    }

    .ProseMirror-menubar {
      @apply rounded-lg !px-3 !py-1.5 z-50 bg-n-background items-center gap-4 ml-0 mb-0 shadow-md outline outline-1 outline-n-weak;
      display: flex;
      width: fit-content !important;
      position: absolute !important;

      // Default/LTR: position from left
      top: var(--selection-top);
      left: var(--selection-left);

      // RTL: position from right instead
      [dir='rtl'] & {
        left: auto;
        right: var(--selection-right);
      }

      .ProseMirror-menuitem {
        @apply mr-0 size-4 flex items-center;

        .ProseMirror-icon {
          @apply p-0.5 flex-shrink-0;
        }
      }

      .ProseMirror-menu-active {
        @apply bg-n-slate-3;
      }
    }
  }
}
</style>
