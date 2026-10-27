require 'net/http'
require 'json'
require 'uri'

abort 'Release checks require a disposable database' unless ENV.fetch('POSTGRES_DATABASE') == 'chatwoot_release_check'
abort 'Enterprise overlay unexpectedly enabled' if ChatwootApp.enterprise?

account = Account.create!(name: 'EasyHire release company')
other_account = Account.create!(name: 'Other release company')
users = %w[admin agent outsider].to_h do |name|
  user = User.new(name: "Release #{name}", email: "release-#{name}@example.test", password: "#{SecureRandom.hex(24)}!Aa1")
  user.skip_confirmation!
  user.save!
  [name, user]
end
AccountUser.create!(account: account, user: users.fetch('admin'), role: :administrator)
AccountUser.create!(account: account, user: users.fetch('agent'), role: :agent)
AccountUser.create!(account: other_account, user: users.fetch('outsider'), role: :agent)
inbox = Inbox.create!(account: account, name: 'Release website', enable_auto_assignment: false,
                      channel: Channel::WebWidget.create!(account: account, website_url: 'http://example.test'))
team = Team.create!(account: account, name: 'Release HR')
TeamMember.create!(team: team, user: users.fetch('agent'))

request = lambda do |method, endpoint, token, payload = nil|
  uri = URI.join(ENV.fetch('FRONTEND_URL'), endpoint)
  headers = { 'api_access_token' => token, 'Content-Type' => 'application/json' }
  response = Net::HTTP.start(uri.host, uri.port) do |http|
    http.send_request(method, uri.request_uri, payload&.to_json, headers)
  end
  [response.code.to_i, response.body.empty? ? {} : JSON.parse(response.body)]
end
checks = []
admin_token = users.fetch('admin').access_token.token
agent_token = users.fetch('agent').access_token.token
base = "/api/v1/accounts/#{account.id}"

status, body = request.call('GET', "#{base}/inboxes", agent_token)
abort 'Team membership must not grant Inbox access' unless status == 200 && body.fetch('payload').empty?
checks << 'team_does_not_grant_inbox'

status, = request.call('POST', "#{base}/inbox_members", agent_token, inbox_id: inbox.id, user_ids: [users.fetch('agent').id])
abort 'HR must not manage Inbox members' unless status == 403
checks << 'hr_cannot_manage_inbox'

status, = request.call('POST', "#{base}/inbox_members", admin_token, inbox_id: inbox.id, user_ids: [users.fetch('outsider').id])
abort 'Cross-company Inbox member must be rejected' unless status == 422 && !InboxMember.exists?(inbox: inbox, user: users.fetch('outsider'))
checks << 'cross_company_member_rejected'

status, = request.call('POST', "#{base}/inbox_members", admin_token, inbox_id: inbox.id, user_ids: [users.fetch('agent').id])
abort 'HR Admin failed to grant Inbox access' unless status == 200
status, body = request.call('GET', "#{base}/inboxes", agent_token)
abort 'Explicit Inbox grant missing' unless status == 200 && body.fetch('payload').map { |entry| entry.fetch('id') } == [inbox.id]
checks << 'explicit_inbox_grant'

contact = Contact.create!(account: account, name: 'Release candidate', email: 'candidate@example.test')
contact_inbox = ContactInbox.create!(contact: contact, inbox: inbox, source_id: SecureRandom.uuid)
conversation = Conversation.create!(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
conversation_path = "#{base}/conversations/#{conversation.display_id}"
status, = request.call('POST', "#{conversation_path}/assignments", admin_token, assignee_id: users.fetch('outsider').id)
abort 'Cross-company assignment must be rejected' unless status == 404
checks << 'cross_company_assignment_rejected'
status, = request.call('POST', "#{conversation_path}/assignments", admin_token, assignee_id: users.fetch('agent').id)
abort 'Agent assignment failed' unless status == 200 && conversation.reload.assignee_id == users.fetch('agent').id
status, = request.call('POST', "#{conversation_path}/assignments", admin_token, team_id: team.id)
abort 'Team assignment failed' unless status == 200 && conversation.reload.team_id == team.id
checks << 'agent_and_team_assignment'

status, body = request.call('POST', "#{conversation_path}/messages", agent_token, content: 'Release message', message_type: 'outgoing')
abort 'Message creation failed' unless status == 200 && body.fetch('content') == 'Release message'
checks << 'outgoing_message'
status, = request.call('POST', "#{conversation_path}/messages", agent_token, content: 'Disabled note', private: true)
abort 'Private Note creation must remain disabled' unless status == 422
checks << 'private_note_remains_disabled'

app = PlatformApp.create!(name: 'EasyHire release SSO')
PlatformAppPermissible.create!(platform_app: app, permissible: users.fetch('agent'))
status, body = request.call('GET', "/platform/api/v1/users/#{users.fetch('agent').id}/login", app.access_token.token)
abort 'Platform SSO failed' unless status == 200
sso_url = URI.parse(body.fetch('url'))
sso_params = URI.decode_www_form(sso_url.query).to_h
abort 'Invalid SSO token' unless users.fetch('agent').valid_sso_auth_token?(sso_params.fetch('sso_auth_token'))
checks << 'platform_sso'

puts JSON.generate(status: 'PASS', edition: 'ce', checks: checks)
