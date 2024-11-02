# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PATCH /v1/admin/contacts" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  let(:headers) { auth_headers }
  let(:params) { { value: } }
  let(:value) { "info#{SecureRandom.hash}@example.com" }
  let(:key) { "email" }

  def req(_k = key, p = params, h = headers)
    patch "/v1/admin/contacts/#{key}", headers: h, params: p
  end

  context "when not authenticated" do
    let(:headers) { {} }

    it do
      req
      expect(response).to have_http_status(:unauthorized)
    end

    it do
      req
      expect(json).to include(message: String)
    end
  end

  context "when contact does not exist" do
    it { expect(Contact.count).to eq 0 }

    it { expect { req }.to(change(Contact, :count).by(1)) }

    it { expect { req }.to change { Contact.where(key:, value:).count }.from(0).to(1) }

    it "if making same request again, will not create again a contact" do
      req
      expect { req }.not_to(change(Contact, :count))
    end

    it "if making same request again, will not update contacts" do
      req
      expect { req }.not_to(change { Contact.all.order(:id).as_json })
    end
  end

  # ####################
  # MANDATORY FIELDS
  # ####################
  %w[
    email
    phone
    homepage_url
  ].each do |contact_key|
    context "won't be able to update #{contact_key.inspect} to blank" do
      before { Contact.create_missing }

      let(:contact) { Contact.find_by(key: contact_key) }
      let(:key) { contact_key }

      let(:value) { nil }

      it { expect(Contact.where(key: contact_key).count).to eq(1) }

      it { expect(contact.reload.value).to be_present }

      it do
        req
        expect(contact.reload.value).to be_present
      end

      it { expect { req }.not_to(change(Contact, :count)) }

      it { expect { req }.not_to(change { contact.reload.value }) }

      it do
        req
        expect(json).to include(message: String)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ####################
  # OPTIONAL FIELDS
  # ####################
  %w[
    whatsapp_number
    facebook_url
    instagram_url
    tripadvisor_url
    google_url
    address
  ].each do |contact_key|
    context "will be able to update #{contact_key.inspect} to blank" do
      before { Contact.create_missing }

      let(:contact) { Contact.find_by(key: contact_key) }
      let(:key) { contact_key }

      let(:value) { nil }

      it { expect(Contact.where(key: contact_key).count).to eq(1) }

      it { expect(contact.reload.value).to be_present }

      it { expect { req }.not_to(change(Contact, :count)) }

      it { expect { req }.to change { contact.reload.value }.to(nil) }

      it do
        req
        expect(json).not_to include(message: String)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ####################
  # WILL REMOVE WHITESPACES
  # ####################
  [
    { key: "email",           value: "info@example.com" },
    { key: "phone",           value: "+393515590063" },
    { key: "whatsapp_number", value: "+393515590063" },
    { key: "facebook_url",    value: "https://www.facebook.com/Laportadacqua" },
    { key: "instagram_url",   value: "https://www.instagram.com/laportadacqua" },
    { key: "tripadvisor_url", value: "https://www.tripadvisor.it/Restaurant_Review-g187870-d1735599-Reviews-La_Porta_D_Acqua-Venice_Veneto.html" },
    { key: "homepage_url",    value: "https://laportadacqua.com" },
    { key: "google_url",      value: "https://g.page/laportadacqua?share" },
  ].each do |config|
    context "will remove whitespaces from #{config[:key].inspect}" do
      def s
        ws = [
          " ",
          "  ",
          "   ",
        ].sample
        Random.rand(2).zero? ? ws : ""
      end

      let(:key) { config[:key] }

      let(:value) do
        base = config[:value]
        base = "#{base[0]}#{s}#{base[1..]}"
        "#{s}#{base}#{s}"
      end

      it { expect { req }.to(change { Contact.where(key:, value: config[:value]).count }.by(1)) }

      it do
        req
        expect(Contact.find_by(key:).value).not_to include(" ")
      end

      it do
        req
        expect(json).not_to include(message: String)
      end

      it do
        req
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "won't remove whitespaces from address but will strip it." do
    let(:key) { "address" }
    let(:clean_value) { value.strip }
    let(:value) { "  Calle Larga XXII Marzo, 2398, 30124 San Marco, Venezia VE, Italy   " }

    it { expect { req }.to(change { Contact.where(key:, value: clean_value).count }.by(1)) }

    it do
      req
      expect(Contact.find_by(key:).value).to include(" ")
    end

    it do
      req
      expect(Contact.find_by(key:).value).to eq(clean_value)
    end

    it do
      req
      expect(json).not_to include(message: String)
    end

    it do
      req
      expect(response).to have_http_status(:ok)
    end
  end

  context "if updating email and then sending reservation confirmation email, that contact should be included." do
    let!(:email) { "info#{SecureRandom.hex}@example.com" }
    let!(:contact) { create(:contact, key: "email", value: email) }
    let!(:reservation) { create(:reservation) }

    let(:call) do
      reservation.deliver_confirmation_email
    end

    before do
      CreateMissingImages.run!
    end

    it { expect { call }.not_to(change { Contact.all.as_json }) }
    it { expect { call }.not_to(change { Setting.all.as_json }) }
    it { expect { call }.not_to(change { PublicMessage.all.as_json }) }
    it { expect { call }.to change { ActionMailer::Base.deliveries.count }.by(1) }

    it do
      call
      expect(ActionMailer::Base.deliveries.last.text_part.body.encoded).to include(email)
      expect(ActionMailer::Base.deliveries.last.html_part.body.encoded).to include(email)
      expect(ActionMailer::Base.deliveries.last.html_part.body.encoded).to include("mailto:#{email}")
    end
  end
end
