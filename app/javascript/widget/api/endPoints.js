import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';

const createConversation = params => {
  const referrerURL = window.referrerURL || '';
  const search = buildSearchParamsWithLocale(window.location.search);
  return {
    url: `/api/v1/widget/conversations${search}`,
    params: {
      contact: {
        name: params.fullName,
        email: params.emailAddress,
        phone_number: params.phoneNumber,
        custom_attributes: params.contactCustomAttributes,
      },
      message: {
        content: params.message,
        timestamp: new Date().toString(),
        referer_url: referrerURL,
      },
      custom_attributes: params.customAttributes,
    },
  };
};

const sendMessage = (content, replyTo, { customAttributes, labels } = {}) => {
  const referrerURL = window.referrerURL || '';
  const search = buildSearchParamsWithLocale(window.location.search);
  const params = {
    message: {
      content,
      reply_to: replyTo,
      timestamp: new Date().toString(),
      referer_url: referrerURL,
    },
  };
  if (customAttributes && Object.keys(customAttributes).length > 0) {
    params.custom_attributes = customAttributes;
  }
  if (labels && labels.length > 0) {
    params.labels = labels;
  }
  return { url: `/api/v1/widget/messages${search}`, params };
};

const sendAttachment = (
  { attachment, replyTo = null },
  { customAttributes, labels } = {}
) => {
  const { referrerURL = '' } = window;
  const timestamp = new Date().toString();
  const { file } = attachment;

  const formData = new FormData();
  if (typeof file === 'string') {
    formData.append('message[attachments][]', file);
  } else {
    formData.append('message[attachments][]', file, file.name);
  }

  formData.append('message[referer_url]', referrerURL);
  formData.append('message[timestamp]', timestamp);
  if (replyTo !== null) {
    formData.append('message[reply_to]', replyTo);
  }
  if (customAttributes && Object.keys(customAttributes).length > 0) {
    Object.entries(customAttributes).forEach(([key, value]) => {
      formData.append(`custom_attributes[${key}]`, value);
    });
  }
  if (labels && labels.length > 0) {
    labels.forEach(label => {
      formData.append('labels[]', label);
    });
  }
  return {
    url: `/api/v1/widget/messages${window.location.search}`,
    params: formData,
  };
};

const getConversation = ({ before, after }) => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: { before, after },
});

const updateMessage = id => ({
  url: `/api/v1/widget/messages/${id}${window.location.search}`,
});

const getAvailableAgents = token => ({
  url: '/api/v1/widget/inbox_members',
  params: {
    website_token: token,
  },
});

export default {
  createConversation,
  sendMessage,
  sendAttachment,
  getConversation,
  updateMessage,
  getAvailableAgents,
};
