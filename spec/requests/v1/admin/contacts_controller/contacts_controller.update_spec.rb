# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PATCH /v1/admin/contacts" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  let(:headers) { auth_headers }
  let(:params) { { value: } }
  let(:value) { "info#{SecureRandom.hash}@example.com" }
  let(:key) { "email" }

  def req(k = key, p = params, h = headers)
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

  %w[
    email
    phone
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

  %w[
    whatsapp_number
    facebook_url
    instagram_url
    tripadvisor_url
    homepage_url
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
end
