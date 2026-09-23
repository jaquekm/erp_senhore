# frozen_string_literal: true

# The Bling sync cron jobs (stock, products, order statuses...) used to
# hardcode account_id 1 in their cron args, since the app originally served
# a single business. Now that the admin panel can create any number of
# client accounts, this fans the wrapped job out to every account that has
# Bling integration enabled and configured instead of just account 1.
#
# `tenant_id` is inserted where it belongs in the wrapped job's own argument
# list: before `args_before`, between `args_before` and `args_after`.
class TenantFanoutJob < ApplicationJob
  queue_as :default

  def perform(job_class_name, args_before = [], args_after = [])
    job_class = job_class_name.constantize

    Account.bling_sync_enabled_ids.each do |tenant_id|
      job_class.perform_later(*args_before, tenant_id, *args_after)
    rescue StandardError => e
      Rails.logger.error("TenantFanoutJob: failed to enqueue #{job_class_name} for account ##{tenant_id}: #{e.message}")
      Sentry.capture_message("TenantFanoutJob: failed to enqueue #{job_class_name} for account ##{tenant_id}: #{e.message}")
    end
  end
end
