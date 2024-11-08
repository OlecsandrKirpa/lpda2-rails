# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /v1/auth/login" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  let(:default_headers) { auth_headers }
  let(:default_params) { { password: current_user_password } }

  def req(headers: default_headers, params: default_params)
    post "/v1/auth/root", headers:, params:
  end

  context "when user cannot root will receive 403" do
    before { current_user.update!(can_root: false) }

    it do
      req
      expect(response).to have_http_status(:forbidden)
    end

    it do
      req
      expect(json).to include(message: I18n.t("errors.messages.user_cannot_root"))
    end
  end

  context "when correct password is provided receives 200" do
    before { current_user.update!(can_root: true) }

    it { expect { req }.to(change { current_user.reload.root_at }.from(nil)) }

    it { expect { req }.to(change { current_user.reload.root? }.from(false)) }

    it do
      req
      expect(response).to have_http_status(:ok)
    end

    it do
      req
      expect(json).to include(sucess: true)
    end

    it do
      req
      expect(current_user.reload.root?).to be(true)
    end

    it "after some time, won't be root anymore." do
      req
      expect(current_user.reload.root?).to be(true)

      travel_to(1.hour.from_now) do
        expect(current_user.reload.root?).to be(false)
      end
    end
  end

  context "when the wrong passowrd is provided receives 401" do
    let(:default_params) { { password: "wrong_password" } }

    before do
      current_user.update!(can_root: true)
    end

    it { expect { req }.not_to(change { current_user.reload.root_at }) }

    it { expect { req }.not_to(change { current_user.reload.root? }) }

    it do
      req
      expect(response).to have_http_status(:unauthorized)
    end

    it do
      req
      expect(json).to include(details: Hash)
    end

    it do
      req
      expect(json.dig(:details,
                      :password)).to be_present.and(be_a(Array)).and(include(I18n.t("errors.messages.invalid_password")))
    end

    it do
      req
      expect(current_user.reload.root?).to be(false)
    end
  end

  context "when the current user cannot root" do
    before { current_user.update!(can_root: false) }

    it { expect { req }.not_to(change { current_user.reload.root_at }) }

    it { expect { req }.not_to(change { current_user.reload.root? }) }

    it do
      req
      expect(response).to have_http_status(:forbidden)
    end

    it do
      req
      expect(json).to include(details: Hash)
    end

    it do
      req
      expect(json).to include(message: String)
    end
  end
end
