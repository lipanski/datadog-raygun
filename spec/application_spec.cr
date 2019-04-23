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
        app.push_event(Helpers.raygun_event)
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
        7.times { app.push_event(Helpers.raygun_event(event_type: "NewErrorOccurred")) }

        app.pop_new_error_count.should eq(7)
      end

      it "resets the counter after the first call" do
        app = Application.new
        7.times { app.push_event(Helpers.raygun_event(event_type: "NewErrorOccurred")) }
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
        7.times { |id| app.push_event(Helpers.raygun_event(event_type: "NewErrorOccurred", error_url: "url_#{id}", total_occurences: 1)) }

        app.pop_error_count.should eq(7)
      end

      it "resets the counter after the first call" do
        app = Application.new
        7.times { |id| app.push_event(Helpers.raygun_event(event_type: "NewErrorOccurred", error_url: "url_#{id}", total_occurences: 1)) }
        app.pop_error_count

        app.pop_error_count.should eq(0)
      end
    end
  end
end
