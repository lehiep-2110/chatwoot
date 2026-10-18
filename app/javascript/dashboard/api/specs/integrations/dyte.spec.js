import DyteAPIClient from '../../integrations/dyte';
import ApiClient from '../../ApiClient';

describe('#accountAPI', () => {
  it('creates correct instance', () => {
    expect(DyteAPIClient).toBeInstanceOf(ApiClient);
    expect(DyteAPIClient).toHaveProperty('addParticipantToMeeting');
  });

  describe('addParticipantToMeeting', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('creates a valid request', () => {
      DyteAPIClient.addParticipantToMeeting(1);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/dyte/add_participant_to_meeting',
        {
          message_id: 1,
        }
      );
    });
  });
});
