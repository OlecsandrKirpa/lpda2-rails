class CreateLogImagePixels < ActiveRecord::Migration[7.0]
  def change
    create_table :log_image_pixels, id: 'bigserial' do |t|
      t.belongs_to  :image,         null: false, foreign_key: true

      t.references  :record,
                    polymorphic: true,
                    null: false,
                    index: true,
                    comment: %(Record this pixel is associated. Mandatory.)

      t.text        :event_type,    null: false, comment: %(What does this event mean. E.g. "email_open")
      t.text        :secret, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
