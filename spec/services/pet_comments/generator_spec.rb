require "rails_helper"

RSpec.describe PetComments::Generator, type: :service do
  before(:all) do
    setup_master_data
  end

  describe ".for" do
    let(:user) { create(:user) }
    let(:character) { user.active_character }
    let(:event) { :task_completed }
    let(:context) { { task_title: "掃除", difficulty: "medium" } }

    let(:openai_generator) { instance_double(PetComments::OpenaiCommentGenerator) }

    before do
      allow(PetComments::OpenaiCommentGenerator).to receive(:new).and_return(openai_generator)
    end

    context "正常にコメントが生成される場合" do
      before do
        allow(openai_generator).to receive(:call).and_return("頑張ったね")
      end

      it "コメントが返されること" do
        result = described_class.for(event, user: user, context: context)
        expect(result).to eq("頑張ったね")
      end

      it "OpenaiCommentGeneratorが正しい引数で初期化されること" do
        expect(PetComments::OpenaiCommentGenerator).to receive(:new).with(
          event: event,
          character: character,
          user: user,
          context: context
        )
        described_class.for(event, user: user, context: context)
      end

      it "OpenaiCommentGeneratorのcallメソッドが呼ばれること" do
        described_class.for(event, user: user, context: context)
        expect(openai_generator).to have_received(:call)
      end
    end

    context "キャラクターが存在しない場合" do
      let(:user_without_character) { create(:user) }

      before do
        user_without_character.update!(active_character: nil)
      end

      it "nilを返すこと" do
        result = described_class.for(event, user: user_without_character, context: context)
        expect(result).to be_nil
      end

      it "OpenaiCommentGeneratorが呼ばれないこと" do
        described_class.for(event, user: user_without_character, context: context)
        expect(PetComments::OpenaiCommentGenerator).not_to have_received(:new)
      end
    end

    context "キャラクターが死亡している場合" do
      before do
        character.update!(state: :dead, dead_at: Time.current)
      end

      it "nilを返すこと" do
        result = described_class.for(event, user: user, context: context)
        expect(result).to be_nil
      end

      it "OpenaiCommentGeneratorが呼ばれないこと" do
        described_class.for(event, user: user, context: context)
        expect(PetComments::OpenaiCommentGenerator).not_to have_received(:new)
      end
    end

    context "ユーザーが指定されていない場合" do
      it "nilを返すこと" do
        result = described_class.for(event, user: nil, context: context)
        expect(result).to be_nil
      end

      it "OpenaiCommentGeneratorが呼ばれないこと" do
        described_class.for(event, user: nil, context: context)
        expect(PetComments::OpenaiCommentGenerator).not_to have_received(:new)
      end
    end

    context "OpenaiCommentGeneratorがnilを返す場合" do
      before do
        allow(openai_generator).to receive(:call).and_return(nil)
      end

      it "nilを返すこと" do
        result = described_class.for(event, user: user, context: context)
        expect(result).to be_nil
      end
    end

    context "異なるイベントタイプの場合" do
      before do
        allow(openai_generator).to receive(:call).and_return("おかえり！")
      end

      it "ログインイベントでコメントが返されること" do
        result = described_class.for(:login, user: user, context: {})
        expect(result).to eq("おかえり！")
      end

      it "レベルアップイベントでコメントが返されること" do
        result = described_class.for(:level_up, user: user, context: {})
        expect(result).to eq("おかえり！")
      end
    end
  end

  describe "#generate" do
    let(:user) { create(:user) }
    let(:character) { user.active_character }
    let(:event) { :task_completed }
    let(:context) { { task_title: "掃除", difficulty: "medium" } }
    let(:generator) do
      described_class.new(
        event: event,
        user: user,
        context: context
      )
    end

    let(:openai_generator) { instance_double(PetComments::OpenaiCommentGenerator) }

    before do
      allow(PetComments::OpenaiCommentGenerator).to receive(:new).and_return(openai_generator)
      allow(openai_generator).to receive(:call).and_return("頑張ったね")
    end

    it "コメントが返されること" do
      result = generator.generate
      expect(result).to eq("頑張ったね")
    end
  end
end
