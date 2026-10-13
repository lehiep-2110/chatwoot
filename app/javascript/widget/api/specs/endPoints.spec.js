import endPoints from '../endPoints';

describe('#sendMessage', () => {
  it('returns correct payload', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '?param=1',
    });

    window.WOOT_WIDGET = {
      $root: {
        $i18n: {
          locale: 'ar',
        },
      },
    };

    expect(endPoints.sendMessage('hello')).toEqual({
      url: `/api/v1/widget/messages?param=1&locale=ar`,
      params: {
        message: {
          content: 'hello',
          referer_url: '',
          timestamp: 'mock date',
        },
      },
    });
    spy.mockRestore();
  });
});

describe('#createConversation', () => {
  it('includes contact custom attributes in the payload', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '?param=1',
    });

    window.WOOT_WIDGET = {
      $root: { $i18n: { locale: 'ar' } },
    };

    const result = endPoints.createConversation({
      fullName: 'John',
      emailAddress: 'john@example.com',
      phoneNumber: '+919745313456',
      message: 'hey',
      customAttributes: { order_id: '12345' },
      contactCustomAttributes: { cpf: '123.456.789-09' },
    });

    expect(result).toEqual({
      url: `/api/v1/widget/conversations?param=1&locale=ar`,
      params: {
        contact: {
          name: 'John',
          email: 'john@example.com',
          phone_number: '+919745313456',
          custom_attributes: { cpf: '123.456.789-09' },
        },
        message: {
          content: 'hey',
          timestamp: 'mock date',
          referer_url: '',
        },
        custom_attributes: { order_id: '12345' },
      },
    });
    spy.mockRestore();
  });
});

describe('#sendMessage with pending metadata', () => {
  it('includes custom_attributes and labels in payload', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '?param=1',
    });

    window.WOOT_WIDGET = {
      $root: { $i18n: { locale: 'ar' } },
    };

    const result = endPoints.sendMessage('hello', null, {
      customAttributes: { plan: 'enterprise' },
      labels: ['vip'],
    });

    expect(result.params.custom_attributes).toEqual({ plan: 'enterprise' });
    expect(result.params.labels).toEqual(['vip']);
    spy.mockRestore();
  });

  it('does not include metadata keys when not provided', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '?param=1',
    });

    window.WOOT_WIDGET = {
      $root: { $i18n: { locale: 'ar' } },
    };

    const result = endPoints.sendMessage('hello');
    expect(result.params.custom_attributes).toBeUndefined();
    expect(result.params.labels).toBeUndefined();
    spy.mockRestore();
  });
});

describe('#getConversation', () => {
  it('returns correct payload', () => {
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '',
    });
    expect(endPoints.getConversation({ before: 123 })).toEqual({
      url: `/api/v1/widget/messages`,
      params: {
        before: 123,
      },
    });
  });
});

describe('#getConversation', () => {
  it('should returns correct payload', () => {
    const spy = vi.spyOn(global, 'Date').mockImplementation(() => ({
      toString: () => 'mock date',
    }));
    vi.spyOn(window, 'location', 'get').mockReturnValue({
      ...window.location,
      search: '',
    });
    expect(
      endPoints.getConversation({
        after: 123,
      })
    ).toEqual({
      url: `/api/v1/widget/messages`,
      params: {
        after: 123,
        before: undefined,
      },
    });

    spy.mockRestore();
  });
});
