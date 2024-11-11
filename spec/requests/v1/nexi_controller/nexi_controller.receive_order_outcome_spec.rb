# frozen_string_literal: true

require "rails_helper"

RSpec.context "POST /v1/nexi/receive_order_outcome", type: :request do
  let!(:reservation) { create(:reservation) }
  let!(:payment) { create(:reservation_payment, reservation:) }
  let(:default_params) do
    {
      # esito:
      esito:,
      codiceEsito:,
      messaggio:,
      codAut:,
      alias:,
      importo:,
      divisa:,
      codTrans:,
      data:,
      orario:,
      mac:,
      pan:,
      scadenza_pan:,
      brand:,
      nazionalita:,
      languageId:,
      tipoTransazione:,
    }
  end

  # https://ecommerce.nexi.it/specifiche-tecniche/codicebase/esito.html

  # Esito dell'operazione. Valori possibili:
  # - OK
  # - KO
  # - ANNULLO
  # - ERRORE
  # - PEN: stato pendente
  let(:esito) { "OK" }

  # https://ecommerce.nexi.it/specifiche-tecniche/tabelleecodifiche/codificadescrizioneesito.html
  let(:codiceEsito) { "0" }

  # https://ecommerce.nexi.it/specifiche-tecniche/tabelleecodifiche/codificaesiti.html
  let(:messaggio) { "Message OK" }

  let(:codAut) { "AB" }

  let(:alias) { "alias" }

  let(:importo) { 5000 }

  let(:divisa) { "EUR" }

  let(:codTrans) { payment.external_id }

  # aaaammgg
  let(:data) { "20241111" }

  # AN MAX 6 hhmmss
  let(:orario) { "172401" }

  let(:mac) { "mac" }

  let(:pan) { "**********0912" }

  # DATA aaaamm
  let(:scadenza_pan) { "202411" }

  let(:brand) { "VISA" }

  # AN MIN 3 MAX 3 Codifica ISO 3166-1 alpha-3
  let(:nazionalita) { "ITA" }

  # https://ecommerce.nexi.it/specifiche-tecniche/tabelleecodifiche/codificalanguageid.html
  let(:languageId) { "ITA" }

  # https://ecommerce.nexi.it/specifiche-tecniche/tabelleecodifiche/codificatipotransazione.html
  let(:tipoTransazione) { "3DS_FULL" }

  def req(params: default_params)
    post "/v1/nexi/receive_order_outcome", params:
  end

  it do
    req
    expect(response).to have_http_status(:ok)
  end

  it { expect { req }.to change { payment.reload.status }.from("todo").to("paid") }
  it { expect { req }.to change { reservation.events.count }.by(1) }
  it { expect { req }.to(change { Nexi::OrderOutcomeRequest.count }.by(1)) }
  it { expect { req }.to(change { Log::ReservationEvent.count }.by(1)) }
  it do
    req
    expect(Log::ReservationEvent.last.payload).to include("ip" => String)
  end

  [
    "KO",
    "ANNULLO",
    "ERRORE",
  ].each do |failure_esito|
    context "when esito is #{failure_esito.inspect}" do
      let(:esito) { failure_esito }

      it { expect { req }.to(change { Nexi::OrderOutcomeRequest.count }.by(1)) }

      it { expect { req }.not_to(change { payment.reload.status }) }

      it { expect { req }.to change { reservation.events.count }.by(1) }

      it do
        req
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when payment is already paid" do
    before do
      payment.paid!
    end

    it { expect { req }.not_to(change { payment.reload.status }) }
    it { expect { req }.to(change { reservation.events.count }) }
    it { expect { req }.to(change { Nexi::OrderOutcomeRequest.count }.by(1)) }
  end
end
