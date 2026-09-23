# frozen_string_literal: true

namespace :admin do
  desc 'Create or update the first admin login. Usage: rails admin:create_user EMAIL=you@example.com PASSWORD=xxxxxx NAME="Your Name"'
  task create_user: :environment do
    email = ENV.fetch('EMAIL') { abort('EMAIL is required, e.g. rails admin:create_user EMAIL=you@example.com PASSWORD=xxxxxx') }
    password = ENV.fetch('PASSWORD') { abort('PASSWORD is required') }
    name = ENV.fetch('NAME', 'Administrador')

    admin_user = AdminUser.find_or_initialize_by(email: email)
    admin_user.name = name
    admin_user.password = password
    admin_user.save!

    puts "Admin user ready: #{admin_user.email}"
  end
end
