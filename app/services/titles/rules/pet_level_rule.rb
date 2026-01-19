module Titles
  module Rules
    class PetLevelRule
      def initialize(user:, threshold:)
        @user = user
        @threshold = threshold
      end

      def satisfied?
        return false unless character

        character.level >= threshold
      end

      private

      attr_reader :user, :threshold

      def character
        user.active_character
      end
    end
  end
end
