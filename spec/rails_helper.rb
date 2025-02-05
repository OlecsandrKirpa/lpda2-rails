# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "database_cleaner"
require "factory_bot_rails"
require "shoulda/matchers"
require "faker"
require "rails-controller-testing"
require "webmock/rspec"
require_relative "coverage_helper"
require "roo"

# https://github.com/sidekiq/sidekiq/wiki/Testing
require "sidekiq/testing"
Sidekiq::Testing.fake!

# require 'sidekiq-status/testing/inline'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/contexts/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/shared_examples/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/matchers/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
# begin
#   ActiveRecord::Migration.maintain_test_schema!
# rescue ActiveRecord::PendingMigrationError => e
#   abort e.to_s.strip
# end
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include RequestSpecHelper, type: :request
  config.include ControllersHelper, type: :controller
  config.include ActiveJob::TestHelper
  config.include ActionCable::TestHelper
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)

    ApplicationCable::Channel.class_eval do
      def self.broadcast_to(*_args)
        return if Rails.env.test?

        super
      end
    end
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before do |example|
    DatabaseCleaner.start unless example.metadata[:skip_db_cleaner]

    if example.metadata[:perform_enqueued_jobs]
      @old_perform_enqueued_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_jobs
      @old_perform_enqueued_at_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    end
  end

  config.append_after do |example|
    DatabaseCleaner.clean unless example.metadata[:skip_db_cleaner]

    Faker::UniqueGenerator.clear unless example.metadata[:skip_faker_reset]

    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false

    if example.metadata[:perform_enqueued_jobs]
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = @old_perform_enqueued_jobs
      ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = @old_perform_enqueued_at_jobs
    end
  end

  # config.before(:each) do
  #   DatabaseCleaner.start
  # end

  # config.after(:each) do
  #   DatabaseCleaner.clean
  # end

  # Classic RSpec
  config.formatter = :documentation
  config.color = true

  # RSpec HTML Report
  # config.formatter = :html
  # config.output_stream = File.open('spec/reports/rspec.html', 'w')

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
