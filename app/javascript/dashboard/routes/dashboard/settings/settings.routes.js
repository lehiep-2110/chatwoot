import { frontendURL } from '../../../helper/URLHelper';

import account from './account/account.routes';
import agent from './agents/agent.routes';
import assignmentPolicy from './assignmentPolicy/assignmentPolicy.routes';
import agentBot from './agentBots/agentBot.routes';
import attributes from './attributes/attributes.routes';
import automation from './automation/automation.routes';
import auditlogs from './auditlogs/audit.routes';
import billing from './billing/billing.routes';
import inbox from './inbox/inbox.routes';
import templates from './templates/templates.routes';
import integrations from './integrations/integrations.routes';
import labels from './labels/labels.routes';
import teams from './teams/teams.routes';
import profile from './profile/profile.routes';
import security from './security/security.routes';
import conversationWorkflow from './conversationWorkflow/conversationWorkflow.routes';
import data from './data/data.routes';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings'),
      name: 'settings_home',
      meta: {
        permissions: ['administrator'],
      },
      redirect: to => ({
        name: 'settings_inbox_list',
        params: to.params,
      }),
    },
    ...account.routes,
    ...agent.routes,
    ...assignmentPolicy.routes,
    ...agentBot.routes,
    ...attributes.routes,
    ...automation.routes,
    ...auditlogs.routes,
    ...billing.routes,
    ...inbox.routes,
    ...templates.routes,
    ...integrations.routes,
    ...data.routes,
    ...labels.routes,
    ...teams.routes,
    ...profile.routes,
    ...security.routes,
    ...conversationWorkflow.routes,
  ],
};
