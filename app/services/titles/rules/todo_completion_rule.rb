module Titles
  module Rules
    class TodoCompletionRule
      def initialize(user:, threshold:)
        @user = user
        @threshold = threshold
      end

      def satisfied?
        completed_todo_count >= threshold
      end

      private

      attr_reader :user, :threshold

      def completed_todo_count
        TaskEvent.where(user_id: user.id, action: :completed, task_kind: :todo)
          .sum(:delta)
      end
    end
  end
end
