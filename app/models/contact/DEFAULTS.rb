# frozen_string_literal: true

class Contact
  DEFAULTS = {
    address: {
      value: "Riva del Vin San Polo 1097 San Polo, 30125 Venice Italy",
      strip: true
    },
    email: {
      value: "info@laportadacqua.com",
      required: true,
      remove_whitespaces: true
    },
    phone: {
      value: "+390412412124",
      required: true,
      remove_whitespaces: true
    },
    whatsapp_number: {
      value: "+390412412124",
      remove_whitespaces: true
    },
    facebook_url: {
      value: "https://www.facebook.com/Laportadacqua",
      remove_whitespaces: true
    },
    instagram_url: {
      value: "https://www.instagram.com/laportadacqua",
      remove_whitespaces: true
    },
    tripadvisor_url: {
      value: "https://www.tripadvisor.it/Restaurant_Review-g187870-d1735599-Reviews-La_Porta_D_Acqua-Venice_Veneto.html",
      remove_whitespaces: true
    },
    homepage_url: {
      value: "https://laportadacqua.com",
      required: true,
      remove_whitespaces: true
    },
    google_url: {
      value: "https://g.page/laportadacqua?share",
      remove_whitespaces: true
    }
  }.with_indifferent_access.freeze
end
