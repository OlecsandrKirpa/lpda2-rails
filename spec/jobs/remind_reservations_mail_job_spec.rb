# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemindReservationsMailJob, type: :job do
  it "should call RemindReservationsMail.run!" do
    allow(RemindReservationsMail).to receive(:run!).and_return(true)
    described_class.perform_async
    described_class.perform_one
    expect(RemindReservationsMail).to have_received(:run!).once
  end
end
