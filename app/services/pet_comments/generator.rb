module PetComments
  class Generator
    def self.for(event, user: nil, context: {})
      new(event: event, user: user, context: context).generate
    end

    def initialize(event:, user: nil, context: {})
      @event = event
      @user = user
      @character = user&.active_character
      @context = context
    end

    def generate
      return nil unless character.present?
      return nil if character.dead?

      OpenaiCommentGenerator.new(
        event: event,
        character: character,
        user: user,
        context: context
      ).call
    end

    private

    attr_reader :event, :user, :character, :context
  end
end
