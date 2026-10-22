# Preserve stored tool identifiers and validation without loading retired executable tools.
module Concerns::CaptainToolsHelpers
  extend ActiveSupport::Concern

  TOOL_REFERENCE_REGEX = %r{\[[^\]]+\]\(tool://([^/)]+)\)}

  class_methods do
    def built_in_agent_tools
      @built_in_agent_tools ||= YAML.load_file(Rails.root.join('config/agents/tools.yml')).map do |tool|
        { id: tool['id'], title: tool['title'], description: tool['description'], icon: tool['icon'] }
      end
    end

    def built_in_tool_ids
      @built_in_tool_ids ||= built_in_agent_tools.pluck(:id)
    end
  end

  def extract_tool_ids_from_text(text)
    return [] if text.blank?

    text.scan(TOOL_REFERENCE_REGEX).flatten.uniq
  end
end
