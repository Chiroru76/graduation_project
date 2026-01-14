# frozen_string_literal: true

module Characters
  class PetResponseBuilder
    attr_reader :character, :evolution_result, :event_context

    def initialize(character:, evolution_result:, event_context: {})
      @character = character
      @evolution_result = evolution_result
      @event_context = event_context
    end

    def build
      {
        comment: generate_comment,
        appearance: fetch_appearance
      }
    end

    def generate_comment
      return nil if evolution_result[:evolved] || evolution_result[:hatched]

      event = determine_event
      return nil unless event

      PetComments::Generator.for(
        event,
        user: character.user,
        context: event_context
      )
    end

    private

    def determine_event
      if evolution_result[:leveled_up]
        :level_up
      elsif event_context[:task_completed]
        :task_completed
      end
    end

    def fetch_appearance
      return nil unless character&.character_kind

      CharacterAppearance.find_by(
        character_kind: character.character_kind,
        pose: :idle
      )
    end
  end
end
