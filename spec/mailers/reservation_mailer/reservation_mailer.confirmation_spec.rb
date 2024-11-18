# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationMailer do
  subject { mail }

  before do
    CreateMissingImages.run!
  end

  let(:reservation) { create(:reservation) }
  let(:default_params) { reservation.confirmation_email_params }

  context "when calling #confirmation prepended #with(...)" do
    around do |example|
      Time.use_zone(Config.app.dig!(:restaurant_location_time_zone)) do
        example.run
      end
    end

    def mail(params = default_params)
      described_class.with(params).confirmation.deliver_now
    end

    it { expect(mail.to).to eq([reservation.email]) }

    it do
      expect(mail.subject).to eq I18n.t("reservation_mailer.confirmation.subject", fullname: reservation.fullname)
    end

    context "when reservation has a payment in status 'paid'" do
      before do
        create(:reservation_payment, reservation:, status: :paid)
      end

      it { expect(reservation.reload.payment).to be_paid }
      it { expect(mail.text_part.body.encoded).to include(I18n.t("reservation_mailer.confirmation.payment_completed")) }
      it { expect(mail.html_part.body.encoded).to include(CGI.escapeHTML(I18n.t("reservation_mailer.confirmation.payment_completed"))) }
    end

    context "when reservation has a payment in status 'todo'" do
      before do
        create(:reservation_payment, reservation:, status: :todo)
      end

      it { expect(reservation.reload.payment).to be_todo }
      it { expect(mail.text_part.body.encoded).to include(I18n.t("reservation_mailer.confirmation.remember_payment")) }
      it { expect(mail.html_part.body.encoded).to include(CGI.escapeHTML(I18n.t("reservation_mailer.confirmation.remember_payment"))) }
    end

    context "when reservation don't have a payment" do
      it { expect(reservation.reload.payment).to be_nil }
      it { expect(mail.text_part.body.encoded).not_to include(I18n.t("reservation_mailer.confirmation.remember_payment")) }
      it { expect(mail.html_part.body.encoded).not_to include(I18n.t("reservation_mailer.confirmation.remember_payment")) }
      it { expect(mail.html_part.body.encoded).not_to include(CGI.escapeHTML(I18n.t("reservation_mailer.confirmation.remember_payment"))) }
    end

    context "when checking text part body" do
      subject(:body) { mail.text_part.body.encoded }

      it do
        expect(body).not_to include("<a ")
      end

      it do
        expect(body).not_to include("href=")
      end
    end

    %w[it en].each do |lang|
      it "when language is #{lang.inspect}" do
        reservation.update!(lang:)
        expect(mail.subject).to eq I18n.t("reservation_mailer.confirmation.subject", fullname: reservation.fullname,
                                                                                     locale: lang)
      end

      context "when language is #{lang}" do
        it do
          reservation.update!(lang:)
          expect(mail.text_part.body.encoded).to include I18n.t("reservation_mailer.greetings",
                                                                fullname: reservation.fullname, locale: lang)
        end

        it do
          reservation.update!(lang:)
          expect(mail.html_part.body.encoded).to include CGI.escapeHTML(I18n.t("reservation_mailer.greetings",
                                                                               fullname: reservation.fullname, locale: lang))
        end
      end
    end
  end
end
