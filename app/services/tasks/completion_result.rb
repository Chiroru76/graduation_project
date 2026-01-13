# frozen_string_literal: true

module Tasks
  # タスク完了処理の結果を保持するValue Object
  # Task完了時の進化/孵化/レベルアップ状態、ペットレスポンス、称号解除情報を保持
  class CompletionResult
    attr_reader :task, :notice, :growth_result, :pet_response, :unlocked_titles

    def initialize(task:, notice:, growth_result:, pet_response:, unlocked_titles: [])
      @task = task
      @notice = notice
      @growth_result = growth_result
      @pet_response = pet_response
      @unlocked_titles = unlocked_titles
    end

    # ペットが卵から孵化したか？
    def hatched?
      growth_result[:hatched]
    end

    # ペットが子供から大人に進化したか？
    def evolved?
      growth_result[:evolved]
    end

    # レベルアップしたか？（進化/孵化以外）
    def leveled_up?
      growth_result[:leveled_up]
    end

    # ペットコメント（OpenAI生成）
    def pet_comment
      pet_response[:comment]
    end

    # タスクが完了状態か？
    def completed?
      task.done?
    end
  end
end
