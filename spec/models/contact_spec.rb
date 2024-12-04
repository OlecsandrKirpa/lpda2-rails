# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contact do
  describe "#public_formatted" do
    subject { described_class.public_formatted }

    context "when there are no contacts, will equal to defaults" do
      Contact::DEFAULTS.keys.each do |key|
        it { is_expected.to include(key => Contact::DEFAULTS[key][:value]) }
      end
    end

    %i[
      address
      whatsapp_number
      facebook_url
      instagram_url
      tripadvisor_url
      google_url
    ].each do |contact_key|
      [
        "",
        nil
      ].each do |blank_value|
        context "when contact #{contact_key.inspect} has value #{blank_value.inspect}" do
          before { Contact.create!(key: contact_key, value: blank_value) }

          it { is_expected.to include(contact_key => blank_value) }
        end
      end
    end
  end
end
