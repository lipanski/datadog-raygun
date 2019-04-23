require "spec"
require "../src/application"
require "./helpers"

describe Application do
  describe "#tags" do
    it "returns the tags" do
      app = Application.new(["hello", "world"])
      app.tags.should eq(["hello", "world"])
    end
  end

  describe "#active?" do
    describe "when no events have ever been pushed" do
      it "returns false" do
        app = Application.new
        app.active?.should eq(false)
      end
    end

    describe "when events have been pushed and are currently in the queue" do
      it "returns true" do
        app = Application.new
        app << Helpers.raygun_event
        app.active?.should eq(true)
      end
    end
  end

  describe "#pop_new_error_count" do
    describe "when no events have been pushed" do
      it "returns 0" do
        app = Application.new
        app.pop_new_error_count.should eq(0)
      end
    end

    describe "when several new events have been pushed" do
      it "returns the amount of new events" do
        app = Application.new
        7.times { app << Helpers.raygun_event(event_type: "NewErrorOccurred") }

        app.pop_new_error_count.should eq(7)
      end

      it "resets the counter after the first call" do
        app = Application.new
        7.times { app << Helpers.raygun_event(event_type: "NewErrorOccurred") }
        app.pop_new_error_count

        app.pop_new_error_count.should eq(0)
      end
    end
  end

  describe "#pop_error_count" do
    describe "when no events have been pushed" do
      it "returns 0" do
        app = Application.new
        app.pop_error_count.should eq(0)
      end
    end

    describe "when several new events for different errors have been pushed" do
      it "returns the sum of these events" do
        app = Application.new
        7.times { |id| app << Helpers.raygun_event(event_type: "NewErrorOccurred", error_url: "url_#{id}", total_occurences: 1) }

        app.pop_error_count.should eq(7)
      end

      it "resets the counter after the first call" do
        app = Application.new
        7.times { |id| app << Helpers.raygun_event(event_type: "NewErrorOccurred", error_url: "url_#{id}", total_occurences: 1) }
        app.pop_error_count

        app.pop_error_count.should eq(0)
      end
    end

    describe "when two events for the same error and of different types have been pushed" do
      it "returns the difference + 1" do
        app = Application.new
        app << Helpers.raygun_event(event_type: "ErrorReoccurred", total_occurences: 4, last_occurred_at: 5.minutes.ago)
        app << Helpers.raygun_event(event_type: "OneMinuteFollowUp", total_occurences: 7, last_occurred_at: 4.minutes.ago)

        app.pop_error_count.should eq(4)
      end

      it "resets the counter after the first call" do
        app = Application.new
        app << Helpers.raygun_event(event_type: "ErrorReoccurred", total_occurences: 4, last_occurred_at: 5.minutes.ago)
        app << Helpers.raygun_event(event_type: "OneMinuteFollowUp", total_occurences: 7, last_occurred_at: 4.minutes.ago)
        app.pop_error_count

        app.pop_error_count.should eq(0)
      end
    end

    describe "when more than two events for the same error and of different types have been pushed" do
      it "returns the difference between the last and the first + 1" do
        app = Application.new
        app << Helpers.raygun_event(event_type: "ErrorReoccurred", total_occurences: 4, last_occurred_at: 5.minutes.ago)
        app << Helpers.raygun_event(event_type: "OneMinuteFollowUp", total_occurences: 7, last_occurred_at: 4.minutes.ago)
        app << Helpers.raygun_event(event_type: "FiveMinuteFollowUp", total_occurences: 19, last_occurred_at: 1.minutes.ago)

        app.pop_error_count.should eq(19 - 4 + 1)
      end

      it "resets the counter after the first call" do
        app = Application.new
        app << Helpers.raygun_event(event_type: "ErrorReoccurred", total_occurences: 4, last_occurred_at: 5.minutes.ago)
        app << Helpers.raygun_event(event_type: "OneMinuteFollowUp", total_occurences: 7, last_occurred_at: 4.minutes.ago)
        app << Helpers.raygun_event(event_type: "FiveMinuteFollowUp", total_occurences: 19, last_occurred_at: 1.minutes.ago)
        app.pop_error_count

        app.pop_error_count.should eq(0)
      end
    end

    describe "when several events for different errors have been pushed" do
      it "returns the sum of the difference + 1 of all errors" do
        app = Application.new
        app << Helpers.raygun_event(error_url: "2", event_type: "ErrorReoccurred", total_occurences: 10, last_occurred_at: 10.minutes.ago)
        app << Helpers.raygun_event(error_url: "2", event_type: "OneMinuteFollowUp", total_occurences: 11, last_occurred_at: 9.minutes.ago)
        app << Helpers.raygun_event(error_url: "1", event_type: "ErrorReoccurred", total_occurences: 4, last_occurred_at: 5.minutes.ago)
        app << Helpers.raygun_event(error_url: "2", event_type: "FiveMinuteFollowUp", total_occurences: 45, last_occurred_at: 5.minutes.ago)
        app << Helpers.raygun_event(error_url: "1", event_type: "OneMinuteFollowUp", total_occurences: 7, last_occurred_at: 4.minutes.ago)
        app << Helpers.raygun_event(error_url: "1", event_type: "FiveMinuteFollowUp", total_occurences: 19, last_occurred_at: 1.minutes.ago)
        app << Helpers.raygun_event(error_url: "2", event_type: "TenMinuteFollowUp", total_occurences: 45, last_occurred_at: 1.minutes.ago)

        app.pop_error_count.should eq((45 - 10 + 1) + (19 - 4 + 1))
      end
    end
  end
end
