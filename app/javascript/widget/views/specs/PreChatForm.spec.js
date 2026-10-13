import { shallowMount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import PreChatFormView from '../PreChatForm.vue';

global.chatwootWebChannel = {
  preChatFormEnabled: true,
  preChatFormOptions: { pre_chat_fields: [], pre_chat_message: '' },
};

describe('PreChatForm view', () => {
  let createConversation;
  let setCustomAttributes;
  let store;

  beforeEach(() => {
    createConversation = vi.fn();
    setCustomAttributes = vi.fn();
    store = createStore({
      modules: {
        conversation: {
          namespaced: true,
          actions: { createConversation, clearConversations: vi.fn() },
        },
        conversationAttributes: {
          namespaced: true,
          actions: { clearConversationAttributes: vi.fn() },
        },
        contacts: {
          namespaced: true,
          actions: { setCustomAttributes },
        },
      },
    });
  });
  const mountView = () =>
    shallowMount(PreChatFormView, { global: { plugins: [store] } });

  it('sends contact custom attributes with the conversation create request', async () => {
    const wrapper = mountView();
    wrapper.vm.onSubmit({
      fullName: 'John',
      emailAddress: 'john@example.com',
      message: 'hey',
      contactCustomAttributes: { cpf: '123.456.789-09' },
      conversationCustomAttributes: { order_id: '12345' },
    });
    await flushPromises();

    expect(createConversation).toHaveBeenCalledWith(expect.anything(), {
      fullName: 'John',
      emailAddress: 'john@example.com',
      message: 'hey',
      phoneNumber: undefined,
      customAttributes: { order_id: '12345' },
      contactCustomAttributes: { cpf: '123.456.789-09' },
    });
    // attributes ride along in the create request itself; a separate call
    // would race the contact merge on the server and write to a destroyed
    // contact
    expect(setCustomAttributes).not.toHaveBeenCalled();
  });
});
