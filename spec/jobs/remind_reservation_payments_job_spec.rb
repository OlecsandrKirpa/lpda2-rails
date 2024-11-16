# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemindReservationPaymentsJob, type: :job do
  it "calls RemindReservationPayments.run!" do
    allow(RemindReservationPayments).to receive(:run!).and_return(true)
    described_class.perform_async
    described_class.perform_one
    expect(RemindReservationPayments).to have_received(:run!).once
  end
end
