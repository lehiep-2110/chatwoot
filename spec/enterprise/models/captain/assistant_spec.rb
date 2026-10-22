require 'rails_helper'

RSpec.describe Captain::Assistant, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'US' }) }
  let(:conversation) { create(:conversation, account: account, contact: contact) }

  describe 'associations' do
    it 'keeps Captain and AgentBot conversations separate when their ids match' do
      assistant = create(:captain_assistant, id: 999_999, account: account)
      agent_bot = create(:agent_bot, id: assistant.id, account: account)
      captain_conversation = create(:conversation, account: account, ai_assignee: assistant)
      agent_bot_conversation = create(:conversation, account: account, ai_assignee: agent_bot)

      expect(assistant.assigned_conversations).to contain_exactly(captain_conversation)
      expect(agent_bot.assigned_conversations).to contain_exactly(agent_bot_conversation)
    end
  end

  describe 'inactive conversation settings' do
    it 'uses safe defaults when settings are unavailable' do
      assistant.account.enable_features('captain_integration_v2')
      assistant.auto_resolve_after = nil

      expect(assistant.inactivity_threshold_minutes).to eq(60)

      assistant.auto_resolve_after = 5
      assistant.send_inactivity_resolution_message = false
      assistant.account.disable_features('captain_integration_v2')

      expect(assistant.inactivity_threshold_minutes).to eq(60)
      expect(assistant.send_inactivity_resolution_message?).to be(true)
    end

    it 'validates the inactivity timer range' do
      assistant.auto_resolve_after = 4

      expect(assistant).not_to be_valid
      expect(assistant.errors[:auto_resolve_after]).to be_present

      assistant.auto_resolve_after = 61.5

      expect(assistant).not_to be_valid
      expect(assistant.errors[:auto_resolve_after]).to be_present
    end

    it 'rounds the inactivity timer to the nearest five minutes' do
      assistant.auto_resolve_after = 61

      assistant.validate

      expect(assistant.auto_resolve_after).to eq(60)

      assistant.auto_resolve_after = 63
      assistant.validate

      expect(assistant.auto_resolve_after).to eq(65)
    end
  end

  describe '#auto_resolve_mode' do
    let(:account) { create(:account, captain_auto_resolve_mode: 'legacy') }

    it 'uses the assistant setting when configured' do
      assistant = create(:captain_assistant, account: account, config: { 'auto_resolve_mode' => 'disabled' })

      expect(assistant.auto_resolve_mode).to eq('disabled')
    end

    it 'falls back to the account setting for assistants that have not been migrated' do
      assistant = create(:captain_assistant, account: account)

      expect(assistant.auto_resolve_mode).to eq('legacy')
    end

    it 'rejects unsupported modes' do
      assistant = build(:captain_assistant, account: account, config: { 'auto_resolve_mode' => 'unsupported' })

      expect(assistant).not_to be_valid
      expect(assistant.errors[:auto_resolve_mode]).to be_present
    end
  end

  describe 'response_window validation' do
    it 'accepts a blank response_window' do
      assistant.config['response_window'] = nil
      expect(assistant).to be_valid
    end

    it 'accepts the known windows' do
      described_class::RESPONSE_WINDOWS.each do |window|
        assistant.config['response_window'] = window
        expect(assistant).to be_valid
      end
    end

    it 'rejects an unknown window' do
      assistant.config['response_window'] = 'weekends'
      expect(assistant).not_to be_valid
      expect(assistant.errors[:config]).to include('invalid response_window')
    end
  end

  describe 'audience validation' do
    let(:leaf) { { 'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US'] } }

    it 'accepts a blank audience' do
      assistant.config['audience'] = nil
      expect(assistant).to be_valid
    end

    it 'accepts a single leaf' do
      assistant.config['audience'] = leaf
      expect(assistant).to be_valid
    end

    it 'accepts symbol keys' do
      assistant.config['audience'] = { attribute_key: 'country_code', filter_operator: 'equal_to', values: ['US'] }
      expect(assistant).to be_valid
    end

    it 'accepts a well-formed nested tree' do
      assistant.config['audience'] = {
        'operator' => 'and',
        'conditions' => [
          { 'operator' => 'or', 'conditions' => [leaf] },
          leaf
        ]
      }
      expect(assistant).to be_valid
    end

    it 'rejects a node that is not a hash' do
      assistant.config['audience'] = ['not-a-node']
      expect(assistant).not_to be_valid
      expect(assistant.errors[:config]).to include('audience must be a valid condition tree')
    end

    it 'rejects an unknown operator' do
      assistant.config['audience'] = leaf.merge('filter_operator' => 'bogus')
      expect(assistant).not_to be_valid
    end

    it 'rejects an operator unsupported by a standard attribute' do
      assistant.config['audience'] = leaf.merge('attribute_key' => 'blocked', 'filter_operator' => 'is_not_present', 'values' => [])
      expect(assistant).not_to be_valid
    end

    it 'rejects a leaf missing attribute_key' do
      assistant.config['audience'] = { 'filter_operator' => 'equal_to', 'values' => ['US'] }
      expect(assistant).not_to be_valid
    end

    it 'rejects conversation language conditions' do
      assistant.config['audience'] = {
        'attribute_key' => 'conversation_language', 'filter_operator' => 'equal_to', 'values' => ['en']
      }

      expect(assistant).not_to be_valid
    end

    it 'rejects an unknown custom attribute' do
      assistant.config['audience'] = {
        'attribute_key' => 'missing_attribute', 'filter_operator' => 'not_equal_to', 'values' => ['known']
      }

      expect(assistant).not_to be_valid
    end

    it 'accepts an operator supported by a defined custom attribute' do
      create(:custom_attribute_definition, account: account, attribute_model: :contact_attribute,
                                           attribute_display_type: :date, attribute_key: 'signed_up_on')
      assistant.config['audience'] = {
        'attribute_key' => 'signed_up_on', 'filter_operator' => 'is_present', 'values' => []
      }

      expect(assistant).to be_valid
    end

    it 'rejects a group without conditions' do
      assistant.config['audience'] = { 'operator' => 'and', 'conditions' => [] }
      expect(assistant).not_to be_valid
    end

    it 'rejects an unknown group operator' do
      assistant.config['audience'] = { 'operator' => 'xor', 'conditions' => [leaf] }
      expect(assistant).not_to be_valid
    end

    it 'rejects a value-taking leaf without values' do
      assistant.config['audience'] = { 'attribute_key' => 'email', 'filter_operator' => 'contains' }
      expect(assistant).not_to be_valid
    end

    it 'rejects a valueless operator when the attribute does not support it' do
      assistant.config['audience'] = { 'attribute_key' => 'email', 'filter_operator' => 'is_present' }
      expect(assistant).not_to be_valid
    end

    it 'rejects conditions that is not an array' do
      assistant.config['audience'] = { 'operator' => 'and', 'conditions' => leaf }
      expect(assistant).not_to be_valid
    end

    it 'rejects a group containing an invalid child' do
      assistant.config['audience'] = { 'operator' => 'and', 'conditions' => [leaf, { 'attribute_key' => '' }] }
      expect(assistant).not_to be_valid
    end

    it 'rejects nesting deeper than one level' do
      assistant.config['audience'] = {
        'operator' => 'and',
        'conditions' => [
          { 'operator' => 'or', 'conditions' => [
            { 'operator' => 'and', 'conditions' => [leaf] }
          ] }
        ]
      }
      expect(assistant).not_to be_valid
    end
  end

  describe '#available_tool_ids' do
    it 'excludes disabled custom tools' do
      enabled_tool = create(:captain_custom_tool, account: account)
      disabled_tool = create(:captain_custom_tool, :disabled, account: account)

      expect(assistant.available_tool_ids).to include(enabled_tool.slug)
      expect(assistant.available_tool_ids).not_to include(disabled_tool.slug)
    end
  end

  describe '#known_tool_ids' do
    it 'includes disabled custom tools as valid references' do
      disabled_tool = create(:captain_custom_tool, :disabled, account: account)

      expect(assistant.known_tool_ids).to include(disabled_tool.slug)
    end
  end
end
