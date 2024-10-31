# frozen_string_literal: true

redis_configs = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
  size: ActiveRecord::Base.connection_pool.size
}

Sidekiq.configure_server do |config|
  config.on(:startup) do
    ActiveRecord::Base.clear_active_connections!
  end

  # FIX to ActiveRecord::ConnectionTimeoutError when sidekiq concurrency was > ActiveRecord::Base.connection_pool.size
  # config[:concurrency] = ActiveRecord::Base.connection_pool.size

  config.redis = redis_configs
  schedule_file = "config/schedule.yml"
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file)

  # accepts :expiration (optional)
  # Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes.to_i

  # accepts :expiration (optional)
  # Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes.to_i
end

Sidekiq.configure_client do |config|
  config.redis = redis_configs

  # Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes.to_i
end

Sidekiq.strict_args!

# if Sidekiq.server?
#   cron = Ztimer.new(concurrency: 5)
#   cron.every(60 * 1000){ SyncCintEventsJob.perform_later }
#   cron.every(5 * 60 * 1000){ ProcessCintEventsJob.perform_later }
# end
