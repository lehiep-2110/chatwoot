import MessagesView from '../MessagesView.vue';

describe('MessagesView without AI label suggestions', () => {
  let conversationPanel;
  let context;

  beforeEach(() => {
    conversationPanel = document.createElement('div');
    conversationPanel.innerHTML = `
      <li class="message--read"></li>
      <li class="message--unread"></li>
      <li class="message--unread"></li>
    `;
    Object.defineProperty(conversationPanel, 'scrollHeight', { value: 1000 });
    [300, 80, 120].forEach((height, index) => {
      Object.defineProperty(conversationPanel.children[index], 'scrollHeight', {
        value: height,
      });
    });
    context = {
      conversationPanel,
      $el: { scrollHeight: 400 },
      unreadMessageCount: 2,
      isProgrammaticScroll: false,
      fetchAllAttachmentsFromCurrentChat: vi.fn(),
      resetReplyEditorHeight: vi.fn(),
    };
  });

  it('keeps unread messages as the scroll target', () => {
    MessagesView.methods.scrollToBottom.call(context);

    expect(conversationPanel.scrollTop).toBe(600);
    expect(context.isProgrammaticScroll).toBe(true);
  });

  it('scrolls to the last read message when there are no unread messages', () => {
    context.unreadMessageCount = 0;
    Array.from(conversationPanel.children).forEach(element => {
      element.className = 'message--read';
    });

    MessagesView.methods.scrollToBottom.call(context);

    expect(conversationPanel.scrollTop).toBe(680);
  });

  it('reloads attachments and resets the editor height when switching chats', () => {
    MessagesView.watch.currentChat.call(context, { id: 2 }, { id: 1 });

    expect(context.fetchAllAttachmentsFromCurrentChat).toHaveBeenCalledTimes(1);
    expect(context.resetReplyEditorHeight).toHaveBeenCalledTimes(1);
  });

  it('keeps the editor height and attachments when the same chat updates', () => {
    MessagesView.watch.currentChat.call(context, { id: 1 }, { id: 1 });

    expect(context.fetchAllAttachmentsFromCurrentChat).not.toHaveBeenCalled();
    expect(context.resetReplyEditorHeight).not.toHaveBeenCalled();
  });
});
