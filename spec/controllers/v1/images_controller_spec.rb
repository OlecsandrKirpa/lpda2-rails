# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::ImagesController, type: :controller do
  include_context CONTROLLER_UTILS_CONTEXT
  # include_context CONTROLLER_AUTHENTICATION_CONTEXT
  include_context TESTS_OPTIMIZATIONS_CONTEXT

  let(:instance) { described_class.new }

  context 'GET #index' do
    it { expect(instance).to respond_to(:index) }
    it { should route(:get, '/v1/images').to(format: :json, action: :index, controller: 'v1/images') }

    let(:params) { {} }

    def req(req_params = params)
      get :index, params: req_params
    end

    it 'should return 200' do
      req
      expect(response).to have_http_status(:ok)
    end

    context 'should return all items' do
      before do
        create_list(:image, 3, :with_attached_image)
        req
      end

      it { expect(parsed_response_body).to include(items: Array, metadata: Hash) }
      it { expect(parsed_response_body[:items]).to all(be_a(Hash)) }
      it { expect(parsed_response_body[:items]).to all(include(id: Integer, url: String)) }
      it { expect(parsed_response_body[:items].count).to eq 3 }
    end

    context "when filtering for record_type and record_id" do
      before do
        create(:menu_category).images << create(:image, :with_attached_image)
        create(:menu_category).images << create(:image, :with_attached_image)
      end

      context "should not return other record's images" do
        it 'checking mock data' do
          expect(Menu::Category.count).to eq 2
          expect(Image.count).to eq 2
          expect(ImageToRecord.count).to eq 2
        end

        context 'basic' do
          before { req(record_type: "Menu::Category", record_id: Menu::Category.all.sample.id) }

          it { expect(response).to have_http_status(:ok) }
          it { expect(parsed_response_body[:items].count).to eq 1 }
        end

        context "should fix record_type as valid class" do
          [
            "menu::category",
            "menu::category ",
            " menu::category ",
            " menu::category",
            " menu::Category",
            " menu::CategorY",
            "meNu::CategorY",
          ].each do |invalid_klass|
            it "when providing record_type: #{invalid_klass.inspect}" do
              req(record_type: invalid_klass, record_id: Menu::Category.all.sample.id)
              expect(response).to have_http_status(:ok)
              expect(parsed_response_body[:items].count).to eq 1
            end
          end
        end
      end

      context "should not duplicate images when associated to many records" do
        before do
          Menu::Category.first.images << create(:image, :with_attached_image)
          Menu::Category.first.images << create(:image, :with_attached_image)
          Menu::Category.last.images << create(:image, :with_attached_image)
          Menu::Category.last.images << create(:image, :with_attached_image)
        end

        it "checking mock data" do
          expect(Menu::Category.count).to eq 2
          expect(Image.count).to eq 6
          expect(ImageToRecord.count).to eq 6
        end

        context 'basic' do
          before { req(record_type: "Menu::Category", record_id: Menu::Category.all.sample.id) }
          subject { parsed_response_body[:items] }

          it { expect(response).to have_http_status(:ok) }
          it { expect(subject.length).to eq 3 }
        end
      end
    end
  end

  context 'POST #create' do
    it { expect(instance).to respond_to(:create) }
    it { should route(:post, '/v1/images').to(format: :json, action: :create, controller: 'v1/images') }

    let(:record_type) { nil }
    let(:record_id) { nil }
    let(:image) { fixture_file_upload('cat.jpeg', 'image/jpeg') }
    let(:params) { { image:, record_type:, record_id: } }

    def req(req_params = params)
      post :create, params: req_params
    end

    it 'should return 200' do
      req
      expect(response).to have_http_status(:ok)
    end

    it { expect { req }.not_to(change { ImageToRecord.count }) }

    context 'when providing {record_type: String, record_id: Integer}' do
      let!(:category) { create(:menu_category) }
      let!(:record_type) { "Menu::Category" }
      let!(:record_id) { category.id }

      subject do
        req
        parsed_response_body
      end

      it do
        subject
        expect(response).to have_http_status(:ok)
      end

      it { expect { subject }.to change { Image.count }.by(1) }
      it { expect { subject }.to change { ImageToRecord.count }.by(1) }
      it { expect { subject }.to change { category.reload.images.count }.by(1) }
    end
  end

  context 'GET #show' do
    it { expect(instance).to respond_to(:show) }
    it { should route(:get, '/v1/images/2').to(format: :json, action: :show, controller: 'v1/images', id: 2) }

    let(:image) { create(:image, :with_attached_image) }
    let(:params) { { id: image.id } }

    def req(req_params = params)
      get :show, params: req_params
    end

    it 'should return 200' do
      req
      expect(response).to have_http_status(:ok)
    end

    context "should return 404" do
      before { req(id: 999_999_999) }
      subject { response }
      it_behaves_like NOT_FOUND
    end

    context 'should include image url' do
      before { req }
      subject { parsed_response_body[:item] }

      it { should include(id: Integer) }
      it { should include(url: String) }
    end
  end

  context 'PATCH #update_record' do
    it { expect(instance).to respond_to(:update_record) }
    it { should route(:patch, '/v1/images/record').to(format: :json, action: :update_record, controller: 'v1/images') }

    let(:all_images) { create_list(:image, 3, :with_attached_image) }
    let(:record) { create(:menu_category) }

    let(:record_type) { "Menu::Category" }
    let(:record_id) { record.id }
    let(:image_ids) { [all_images.sample.id] }
    let(:params) do
      { record_type:, record_id:, image_ids: }
    end

    def req(req_params = params)
      patch :update_record, params: req_params
    end

    it 'should return 200' do
      req
      expect(response).to have_http_status(:ok)
    end

    context "if record could not be found" do
      let(:record_id) { 999_999_999 }

      it { expect { req }.not_to(change { record.reload.images.count }) }
      it do
        req
        expect(parsed_response_body).to include(message: String, details: Hash)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "if invaild record_type" do
      let(:record_type) { "some-invalid-class" }

      it { expect { req }.not_to(change { record.reload.images.count }) }
      it do
        req
        expect(parsed_response_body).to include(message: String, details: Hash)
        expect(response).to have_http_status(:not_found)
      end
    end

    it { expect { req }.to change { record.images.count }.from(0).to(1) }

    context 'should allow to re-order elements' do
      before do
        record.images = all_images
        @order_before = record.images.reload.order(:id).pluck(:id)
      end

      let(:image_ids) { @order_before.reverse }

      context 'mock data' do
        it { expect(record.reload.images.count).to be_positive }
      end

      it { expect { req }.not_to(change { record.reload.images.count }) }
      it { expect { req }.not_to(change { ImageToRecord.count }) }
      it { expect { req }.to(change { ImageToRecord.all.pluck(:id) }) }
      it do
        req
        expect(record.reload.images.pluck(:id)).not_to eq @order_before
        expect(record.reload.images.pluck(:id)).to match_array(@order_before)
      end
    end

    context "should allow to remove all elements by providing {image_ids: nil}" do
      before do
        record.images = all_images
        @order_before = record.images.pluck(:id)
      end

      context 'mock data' do
        it { expect(record.reload.images.count).to be_positive }
      end

      let(:image_ids) { nil }

      it { expect { req }.to(change { record.reload.images.count }.to(0)) }
      it { expect { req }.to(change { ImageToRecord.count }) }
      it do
        req
        expect(response).to have_http_status(:ok)
      end
    end

    context "should allow to remove one element" do
      before do
        record.images = all_images
        @order_before = record.images.pluck(:id)
      end

      let(:to_remove) { all_images.sample.id }
      let(:image_ids) { all_images.filter { |img| img.id != to_remove } }

      context 'mock data' do
        it { expect(record.reload.images.count).to eq all_images.count }
        it { expect(record.reload.images.count).to be_positive }
        it { expect(image_ids.count).to eq(all_images.count - 1) }
        it { expect(Image.where(id: to_remove).count).to eq 1 }
      end

      it { expect { req }.to(change { record.reload.images.count }.by(-1)) }
    end
  end

  context 'PATCH #remove_from_record' do
    it { expect(instance).to respond_to(:remove_from_record) }
    it { should route(:patch, '/v1/images/5/remove_from_record').to(format: :json, action: :remove_from_record, controller: 'v1/images', id: 5) }

    let(:all_images) { create_list(:image, 3, :with_attached_image) }
    let(:record) { create(:menu_category).tap { |cat| cat.images = all_images } }

    let(:record_type) { "Menu::Category" }
    let(:record_id) { record.id }
    let(:image_id) { all_images.sample.id }
    let(:params) do
      { record_type:, record_id:, id: image_id }
    end

    def req(req_params = params)
      patch :remove_from_record, params: req_params
    end

    it 'should return 200' do
      req
      expect(response).to have_http_status(:ok)
    end

    it { expect { req }.to(change { record.reload.images.count }.by(-1)) }
    it do
      expect { req }.to change { record.reload.images.pluck(:id) }.from(record.reload.images.pluck(:id)).to(record.reload.images.pluck(:id) - [image_id])
    end

    context 'should return 404 if cannot find image' do
      let(:image_id) { 999_999_999 }
      before { req }
      it { expect(response).to have_http_status(404) }
    end

    context 'should return 404 if cannot find record because of record type' do
      let(:record_type) { 'invalid-record-type' }
      before { req }

      it { expect(response).to have_http_status(404) }
    end

    context 'should return 404 if cannot find record because of record id' do
      let(:record_id) { 999_999_999 }
      before { req }

      it { expect(response).to have_http_status(404) }
    end
  end

  context 'GET #download' do
    it { expect(instance).to respond_to(:download) }
    it { should route(:get, '/v1/images/23/download').to(format: :json, action: :download, controller: 'v1/images', id: 23) }

    let(:image) { create(:image, :with_attached_image) }

    def req(image_id, params = {})
      get :download, params: params.merge(id: image_id)
    end

    it 'should return 200' do
      req(image.id)
      expect(response).to have_http_status(200)
    end

    it 'should return 404 if cannot find image' do
      req(999_999_999)
      expect(response).to have_http_status(404)
    end

    context 'when has no :attached_image' do
      it 'should return 500' do
        image.attached_image.purge
        req(image.id)
        expect(response).to have_http_status(500)
      end
    end

    context 'when errors on download, should return 500 with message' do
      before do
        allow_any_instance_of(Image).to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
        req(image.id)
      end

      it { expect(response).to have_http_status(500) }
      it { expect(parsed_response_body).to include(message: String) }
    end
  end

  context 'GET #download_variant' do
    it { expect(instance).to respond_to(:download_variant) }
    it { should route(:get, '/v1/images/23/download/blur').to(format: :json, action: :download_variant, controller: 'v1/images', id: 23, variant: 'blur') }
    let(:image) { create(:image, :with_attached_image) }

    def req(image_id, variant, params = {})
      get :download_variant, params: params.merge(id: image_id, variant:)
    end

    context 'should generate "blur" variant runtime' do
      before { image.blur_image&.destroy! }

      it do
        expect { req(image.id, 'blur') }.to change { image.reload.blur_image.present? }.from(false).to(true)
      end

      it do
        expect { req(image.id, 'blur') }.to change { Image.where(tag: 'blur').count }.by(1)
      end
    end

    context 'when variant is not found' do
      it 'should return 404' do
        req(image.id, 'impossible_variant')
        expect(response).to have_http_status(404)
      end
    end

    context 'when has no :attached_image' do
      it 'should return 500' do
        image.generate_image_variants!
        image.blur_image.attached_image.purge
        req(image.id, 'blur')
        expect(response).to have_http_status(500)
      end
    end
  end

  context 'GET #download_by_key' do
    it { expect(instance).to respond_to(:download_by_key) }
    it { should route(:get, '/v1/images/key/wassabratan').to(format: :json, action: :download_by_key, controller: 'v1/images', key: 'wassabratan') }

    let(:image) { create(:image, :with_attached_image, :with_key) }

    let(:params) { { key: image.key } }

    def req(_params = params)
      get :download_by_key, params: _params
    end

    it 'should return 200' do
      req
      expect(response).to have_http_status(200)
      expect(response.body).to eq(image.attached_image.download)
    end

    it 'should return 404 if cannot find image' do
      req(key: 'impossible_key')
      expect(response).to have_http_status(404)
    end

    it 'should return 500 if has no :attached_image' do
      image.attached_image.purge
      req
      expect(response).to have_http_status(500)
    end
  end

  context 'GET #download_by_pixel_secret' do
    it { expect(instance).to respond_to(:download_by_pixel_secret) }
    it { should route(:get, '/v1/images/p/wassabratan').to(format: :json, action: :download_by_pixel_secret, controller: 'v1/images', secret: 'wassabratan') }

    let(:image) { create(:image, :with_attached_image) }
    let(:record) { create(:reservation) }
    let(:pixel) { create(:log_image_pixel, :with_delivered_email, image:, record:) }
    let(:params) { { secret: pixel.secret } }

    def req(_params = params)
      get :download_by_pixel_secret, params: _params
    end

    it 'should return 404 if cannot find image' do
      req(secret: 'impossible_secret')
      expect(response).to have_http_status(404)
    end

    it 'should return 500 if has no :attached_image' do
      image.attached_image.purge
      req
      expect(response).to have_http_status(500)
    end

    it 'should return 200 usually' do
      req
      expect(response).to have_http_status(200)
      expect(response.body).to eq(image.attached_image.download)
    end

    it do
      expect { req }.to change { pixel.events.count }.by(1)
    end

    it do
      expect { req }.to change { Log::ImagePixelEvent.count }.by(1)
    end
  end
end
