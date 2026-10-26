// Moved from editorHelper.spec.js to editorContentHelper.spec.js
// the mock of chatwoot/prosemirror-schema is getting conflicted with other specs
import { getContentNode } from '../editorHelper';

describe('getContentNode', () => {
  let editorView;

  beforeEach(() => {
    editorView = {
      state: {
        schema: {
          nodes: {
            mention: {
              create: vi.fn(),
            },
          },
          text: vi.fn(),
        },
      },
    };
  });

  describe('getMentionNode', () => {
    it('should create a mention node', () => {
      const content = { id: 1, name: 'John Doe' };
      const from = 0;
      const to = 10;
      getContentNode(editorView, 'mention', content, {
        from,
        to,
      });

      expect(editorView.state.schema.nodes.mention.create).toHaveBeenCalledWith(
        {
          userId: content.id,
          userFullName: content.name,
          mentionType: 'user',
        }
      );
    });
  });

  describe('getVariableNode', () => {
    it('should render the resolved value directly when the variable has a value', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.name',
        { from: 0, to: 10 },
        { 'contact.name': 'John' }
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith('John');
    });

    it('should resolve camelCase custom attributes and non-string values', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.custom_attribute.cloudCustomer',
        { from: 0, to: 10 },
        { 'contact.custom_attribute.cloudCustomer': true }
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith('true');
    });

    it('should keep the placeholder when the variable has no value', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.email',
        { from: 0, to: 10 },
        {}
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith(
        '{{contact.email}}'
      );
    });

    it('should keep the placeholder when the value contains Liquid syntax', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.name',
        { from: 0, to: 10 },
        { 'contact.name': '{{agent.email}}' }
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith(
        '{{contact.name}}'
      );
    });
  });

  describe('getEmojiNode', () => {
    it('should create an emoji node', () => {
      const content = '😊';
      const from = 0;
      const to = 2;
      getContentNode(editorView, 'emoji', content, {
        from,
        to,
      });

      expect(editorView.state.schema.text).toHaveBeenCalledWith('😊');
    });
  });

  describe('getContentNode', () => {
    it('should return null for invalid type', () => {
      const content = 'invalid';
      const from = 0;
      const to = 10;
      const { node } = getContentNode(editorView, 'invalid', content, {
        from,
        to,
      });

      expect(node).toBeNull();
    });
  });
});
