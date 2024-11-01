# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PATCH /v1/admin/contacts" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  let(:headers) { auth_headers }
  let(:params) { {} }
  let(:key) { "email" }

  def req(k = key, p = params, h = headers)
    get "/v1/admin/contacts/#{key}", headers: h, params: p
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
    it { expect(Contact.count).to eq(0) }

    it { expect { req }.not_to(change(Contact, :count)) }

    it do
      req
      expect(json).not_to include(message: String)
    end

    it do
      req
      expect(json).to include(key: key, value: Contact::DEFAULTS.dig(key, :value))
    end
  end

  context "when contact does exist" do
    before { Contact.create_missing }

    let(:contact) { Contact.find_by(key: key) }

    it { expect(Contact.count).to be_positive }

    it { expect { req }.not_to(change(Contact, :count)) }

    it do
      req
      expect(json).not_to include(message: String)
    end

    it do
      req
      expect(json).to include(key: contact.key, value: contact.value)
    end
  end
end
