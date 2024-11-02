# frozen_string_literal: true

class Contact
  DEFAULTS = {
    address: {
      value: "Riva del Vin San Polo 1097 San Polo, 30125 Venice Italy"
    },
    email: {
      value: "info@laportadacqua.com",
      required: true
    },
    phone: {
      value: "+390412412124",
      required: true
    },
    whatsapp_number: {
      value: "+390412412124"
    },
    facebook_url: {
      value: "https://www.facebook.com/Laportadacqua"
    },
    instagram_url: {
      value: "https://www.instagram.com/laportadacqua"
    },
    tripadvisor_url: {
      value: "https://www.tripadvisor.it/Restaurant_Review-g187870-d1735599-Reviews-La_Porta_D_Acqua-Venice_Veneto.html"
    },
    homepage_url: {
      value: "https://laportadacqua.com",
      required: true
    },
    google_url: {
      value: "https://g.page/laportadacqua?share"
    }
  }.with_indifferent_access.freeze
end
