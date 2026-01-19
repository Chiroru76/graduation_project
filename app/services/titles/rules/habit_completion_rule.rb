module Titles
  module Rules
    class HabitCompletionRule
      def initialize(user:, threshold:)
        @user = user
        @threshold = threshold
      end

      def satisfied?
        completed_habit_count >= threshold
      end

      private

      attr_reader :user, :threshold

      def completed_habit_count
        TaskEvent
          .where(user_id: user.id, action: :completed, task_kind: :habit)
          .sum(:delta)
      end
    end
  end
end
