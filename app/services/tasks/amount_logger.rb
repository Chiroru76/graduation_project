# frozen_string_literal: true

module Tasks
  # 数量ログ型タスクの記録処理を行うService Object
  # - タスクに数量と単位を記録
  # - ペットの進化/孵化を検出
  # - ペットコメントを生成
  # - CompletionResultを返す（Completerと共通）
  class AmountLogger
    attr_reader :task, :user, :amount, :unit

    def initialize(task, user, amount:, unit:)
      @task = task
      @user = user
      @amount = amount
      @unit = unit
    end

    def call
      Rails.logger.debug "[Tasks::AmountLogger] Starting log for task=#{task.id}, user=#{user.id}, amount=#{amount}, unit=#{unit}"

      return error_result("この習慣は数量ログ型ではありません") unless task.habit? && task.log?

      character = user.active_character
      growth_detector = Characters::GrowthDetector.new(character)

      # タスクに数量を記録（副作用: TaskEvent作成）
      task.log!(by_user: user, amount: amount, unit: unit)

      Rails.logger.debug "[Tasks::AmountLogger] Task logged successfully"

      # 進化/孵化の検出
      growth_result = growth_detector.detect

      Rails.logger.debug "[Tasks::AmountLogger] Evolution result: #{growth_result}"

      # ペットコメント生成
      event_context = { task_title: task.title, difficulty: task.difficulty }
      pet_response = build_pet_response(character, growth_result, event_context)

      # タスクリロード
      task.reload

      # 結果オブジェクトを返す
      CompletionResult.new(
        task: task,
        notice: "記録しました",
        growth_result: growth_result,
        pet_response: pet_response,
        unlocked_titles: [] # 数量ログでは称号付与なし
      )
    end

    private

    def build_pet_response(character, growth_result, event_context)
      return { comment: nil, appearance: nil } unless character

      Characters::PetResponseBuilder.new(
        character: character,
        growth_result: growth_result,
        event_context: event_context
      ).build
    rescue StandardError => e
      Rails.logger.error "[Tasks::AmountLogger] Failed to build pet response: #{e.message}"
      { comment: nil, appearance: nil }
    end

    def error_result(message)
      CompletionResult.new(
        task: task,
        notice: message,
        growth_result: { hatched: false, evolved: false, leveled_up: false },
        pet_response: { comment: nil, appearance: nil },
        unlocked_titles: []
      )
    end
  end
end
