<script>
import { mapGetters, mapActions } from 'vuex';
import { setHeader } from 'widget/helpers/axios';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import configMixin from './mixins/configMixin';
import { getLocale } from './helpers/urlParamsHelper';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import Spinner from 'shared/components/Spinner.vue';
import {
  getExtraSpaceToScroll,
  loadedEventConfig,
} from './helpers/IframeEventHelper';
import {
  ON_AGENT_MESSAGE_RECEIVED,
  ON_UNREAD_MESSAGE_CLICK,
} from './constants/widgetBusEvents';
import { useDarkMode } from 'widget/composables/useDarkMode';
import { useRouter } from 'vue-router';
import { SDK_SET_BUBBLE_VISIBILITY } from '../shared/constants/sharedFrameEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  name: 'App',
  components: {
    Spinner,
  },
  mixins: [configMixin],
  setup() {
    const { prefersDarkMode } = useDarkMode();
    const router = useRouter();

    return { prefersDarkMode, router };
  },
  data() {
    return {
      isMobile: false,
    };
  },
  computed: {
    ...mapGetters({
      conversationSize: 'conversation/getConversationSize',
      hideMessageBubble: 'appConfig/getHideMessageBubble',
      isFetchingList: 'conversation/getIsFetchingList',
      isRightAligned: 'appConfig/isRightAligned',
      isWidgetOpen: 'appConfig/getIsWidgetOpen',
      messageCount: 'conversation/getMessageCount',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      isWidgetStyleFlat: 'appConfig/isWidgetStyleFlat',
      showUnreadMessagesDialog: 'appConfig/getShowUnreadMessagesDialog',
    }),
    isIFrame() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
    isRTL() {
      return this.$root.$i18n.locale
        ? getLanguageDirection(this.$root.$i18n.locale)
        : false;
    },
    isUnreadView() {
      return this.$route.name === 'unread-messages';
    },
  },
  watch: {
    // Keep the notification dot in sync with the unread count. The SDK ignores
    // dot updates while the bubble is hidden, so refresh it when it is back.
    unreadMessageCount() {
      this.handleUnreadNotificationDot();
    },
    hideMessageBubble() {
      this.handleUnreadNotificationDot();
    },
    isRTL: {
      immediate: true,
      handler(value) {
        document.documentElement.dir = value ? 'rtl' : 'ltr';
      },
    },
  },
  mounted() {
    const { websiteToken, locale, widgetColor } = window.chatwootWebChannel;
    this.setLocale(locale);
    this.setWidgetColor(widgetColor);
    this.setWidgetColorVariable(widgetColor);
    setHeader(window.authToken);
    if (this.isIFrame) {
      this.registerListeners();
      this.sendLoadedEvent();
    } else {
      this.fetchOldConversations();
      this.fetchAvailableAgents(websiteToken);
      this.setLocale(getLocale(window.location.search));
    }
    if (this.isRNWebView) {
      this.registerListeners();
      this.sendRNWebViewLoadedEvent();
    }
    this.$store.dispatch('conversationAttributes/getAttributes');
    this.registerUnreadEvents();
  },
  methods: {
    ...mapActions('appConfig', [
      'setAppConfig',
      'setReferrerHost',
      'setWidgetColor',
      'setBubbleVisibility',
      'setColorScheme',
    ]),
    ...mapActions('conversation', ['fetchOldConversations']),
    ...mapActions('agent', ['fetchAvailableAgents']),
    setWidgetColorVariable(widgetColor) {
      if (widgetColor) {
        document.documentElement.style.setProperty(
          '--widget-color',
          widgetColor
        );
      }
    },
    scrollConversationToBottom() {
      const container = this.$el.querySelector('.conversation-wrap');
      container.scrollTop = container.scrollHeight;
    },
    setBubbleLabel() {
      IFrameHelper.sendMessage({
        event: 'setBubbleLabel',
        label: this.$t('BUBBLE.LABEL'),
      });
    },
    setIframeHeight(isFixedHeight) {
      this.$nextTick(() => {
        const extraHeight = getExtraSpaceToScroll();
        IFrameHelper.sendMessage({
          event: 'updateIframeHeight',
          isFixedHeight,
          extraHeight,
        });
      });
    },
    setLocale(localeWithVariation) {
      if (!localeWithVariation) return;
      const { enabledLanguages } = window.chatwootWebChannel;
      const localeWithoutVariation = localeWithVariation.split('_')[0];
      const hasLocaleWithoutVariation = enabledLanguages.some(
        lang => lang.iso_639_1_code === localeWithoutVariation
      );
      const hasLocaleWithVariation = enabledLanguages.some(
        lang => lang.iso_639_1_code === localeWithVariation
      );

      if (hasLocaleWithVariation) {
        this.$root.$i18n.locale = localeWithVariation;
      } else if (hasLocaleWithoutVariation) {
        this.$root.$i18n.locale = localeWithoutVariation;
      }
    },
    registerUnreadEvents() {
      emitter.on(ON_AGENT_MESSAGE_RECEIVED, () => {
        const { name: routeName } = this.$route;
        if ((this.isWidgetOpen || !this.isIFrame) && routeName === 'messages') {
          this.$store.dispatch('conversation/setUserLastSeen');
        }
        this.setUnreadView();
      });
      emitter.on(ON_UNREAD_MESSAGE_CLICK, () => {
        this.router
          .replace({ name: 'messages' })
          .then(() => this.unsetUnreadView());
      });
    },
    setUnreadView() {
      const { unreadMessageCount } = this;
      if (!this.showUnreadMessagesDialog || !this.isIFrame) return;

      // The unread view marks the widget as open, so only the route tells us it
      // is already on screen. Resize it, else the new message gets cut off.
      if (this.$route.name === 'unread-messages') {
        this.setIframeHeight(true);
        return;
      }

      if (unreadMessageCount > 0 && !this.isWidgetOpen) {
        this.router.replace({ name: 'unread-messages' }).then(() => {
          this.setIframeHeight(true);
          IFrameHelper.sendMessage({ event: 'setUnreadMode' });
        });
      }
    },
    unsetUnreadView() {
      if (this.isIFrame) {
        IFrameHelper.sendMessage({ event: 'resetUnreadMode' });
        this.setIframeHeight(false);
      }
    },
    handleUnreadNotificationDot() {
      const { unreadMessageCount } = this;
      if (this.isIFrame) {
        IFrameHelper.sendMessage({
          event: 'handleNotificationDot',
          unreadMessageCount,
        });
      }
    },
    createWidgetEvents(message) {
      const { eventName } = message;
      const isWidgetTriggerEvent = eventName === 'webwidget.triggered';
      if (isWidgetTriggerEvent && this.isUnreadView) {
        return;
      }
      this.$store.dispatch('events/create', { name: eventName });
    },
    registerListeners() {
      const { websiteToken } = window.chatwootWebChannel;
      window.addEventListener('message', e => {
        if (!IFrameHelper.isAValidEvent(e)) {
          return;
        }
        const message = IFrameHelper.getMessage(e);
        if (message.event === 'config-set') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
          this.fetchOldConversations().then(() => this.setUnreadView());
          this.fetchAvailableAgents(websiteToken);
          this.setAppConfig(message);
          this.$store.dispatch('contacts/get');
        } else if (message.event === 'widget-visible') {
          this.scrollConversationToBottom();
        } else if (message.event === 'change-url') {
          const { referrerURL, referrerHost } = message;
          window.referrerURL = referrerURL;
          this.setReferrerHost(referrerHost);
        } else if (message.event === 'toggle-close-button') {
          this.isMobile = message.isMobile;
        } else if (message.event === 'push-event') {
          this.createWidgetEvents(message);
        } else if (message.event === 'set-label') {
          this.$store.dispatch('conversationLabels/create', message.label);
        } else if (message.event === 'remove-label') {
          this.$store.dispatch('conversationLabels/destroy', message.label);
        } else if (message.event === 'set-user') {
          this.$store.dispatch('contacts/setUser', message);
        } else if (message.event === 'set-custom-attributes') {
          this.$store.dispatch(
            'contacts/setCustomAttributes',
            message.customAttributes
          );
        } else if (message.event === 'delete-custom-attribute') {
          this.$store.dispatch(
            'contacts/deleteCustomAttribute',
            message.customAttribute
          );
        } else if (message.event === 'set-conversation-custom-attributes') {
          this.$store.dispatch(
            'conversation/setCustomAttributes',
            message.customAttributes
          );
        } else if (message.event === 'delete-conversation-custom-attribute') {
          this.$store.dispatch(
            'conversation/deleteCustomAttribute',
            message.customAttribute
          );
        } else if (message.event === 'set-locale') {
          this.setLocale(message.locale);
          this.setBubbleLabel();
        } else if (message.event === 'set-color-scheme') {
          this.setColorScheme(message.darkMode);
        } else if (message.event === 'toggle-open') {
          this.$store.dispatch('appConfig/toggleWidgetOpen', message.isOpen);

          const shouldShowMessageView =
            ['home'].includes(this.$route.name) &&
            message.isOpen &&
            this.messageCount;
          const shouldShowHomeView = !message.isOpen && this.isUnreadView;

          if (shouldShowMessageView) {
            this.router.replace({ name: 'messages' });
          }
          if (shouldShowHomeView) {
            this.$store.dispatch('conversation/setUserLastSeen');
            this.unsetUnreadView();
            this.router.replace({ name: 'home' });
          }
        } else if (message.event === SDK_SET_BUBBLE_VISIBILITY) {
          this.setBubbleVisibility(message.hideMessageBubble);
        }
      });
    },
    sendLoadedEvent() {
      IFrameHelper.sendMessage(loadedEventConfig());
    },
    sendRNWebViewLoadedEvent() {
      RNHelper.sendMessage(loadedEventConfig());
    },
  },
};
</script>

<template>
  <div
    v-if="!conversationSize && isFetchingList"
    class="flex items-center justify-center flex-1 h-full bg-n-background"
    :class="{ dark: prefersDarkMode }"
  >
    <Spinner size="" />
  </div>
  <div
    v-else
    class="flex flex-col justify-end h-full"
    :class="{
      'is-mobile': isMobile,
      'is-widget-right': isRightAligned,
      'is-bubble-hidden': hideMessageBubble,
      'is-flat-design': isWidgetStyleFlat,
      'bg-n-slate-2 dark:bg-n-solid-1': !isUnreadView,
      dark: prefersDarkMode,
    }"
  >
    <router-view />
  </div>
</template>

<style lang="scss">
@import 'widget/assets/scss/woot.scss';
</style>
