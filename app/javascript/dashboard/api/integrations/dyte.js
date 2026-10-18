/* global axios */

import ApiClient from '../ApiClient';

class DyteAPI extends ApiClient {
  constructor() {
    super('integrations/dyte', { accountScoped: true });
  }

  addParticipantToMeeting(messageId) {
    return axios.post(`${this.url}/add_participant_to_meeting`, {
      message_id: messageId,
    });
  }
}

export default new DyteAPI();
