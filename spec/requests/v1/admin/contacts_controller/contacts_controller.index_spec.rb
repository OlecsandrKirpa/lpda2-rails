# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /v1/admin/contacts" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  let(:headers) { auth_headers }
  let(:params) { {} }

  def req(p = params, h = headers)
    get "/v1/admin/contacts", headers: h, params: p
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

  context "when authorized" do
    context "when no contacts exist" do
      subject { json }

      before { req }

      it { expect(Contact.count).to eq 0 }

      it { expect(response).to be_successful }
      it { is_expected.to be_a(Hash) }
      it { expect(json[:items]).to be_a(Array) }
      it { expect(json[:items]).not_to be_empty }
      it do
        expect(json[:items]).to all(include(:key, :value))
      end
    end

    context "when some contact exist" do
      let!(:contact) { create(:contact, key: "email", value: "info@example.com") }

      subject { json }

      before { req }

      it { expect(Contact.count).to eq 1 }
      it { expect(Contact.last.key).to eq contact.key }
      it { expect(Contact.last.value).to eq contact.value }

      it { expect(response).to be_successful }
      it { is_expected.to be_a(Hash) }
      it { expect(json[:items]).to be_a(Array) }
      it { expect(json[:items]).not_to be_empty }

      it do
        expect(json[:items]).to all(include(:key, :value))
      end

      it do
        expect(json[:items].find{|j| j[:key] == contact.key }).to include(key: contact.key, value: contact.value)
      end

      it do
        expect(json[:items].pluck(:key)).to include(contact.key)
      end

      it do
        expect(json[:items].pluck(:key).uniq).to eq json[:items].pluck(:key)
      end
    end
  end
end
