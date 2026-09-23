# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Concurrent session limit', type: :request do
  let(:user) { FactoryBot.create(:user, password: 'password123') }

  before { user.account.update!(max_concurrent_sessions: 1) }

  def login(email, password)
    post user_session_path, params: { user: { email: email, password: password } }
  end

  it 'allows a single login to browse normally' do
    login(user.email, 'password123')

    get products_path
    expect(response).to have_http_status(:success)
  end

  it 'signs out a second concurrent login once the account is at its limit' do
    ActionDispatch::Integration::Session.new(Rails.application).tap do |first_session|
      first_session.post user_session_path, params: { user: { email: user.email, password: 'password123' } }
      first_session.get products_path
      expect(first_session.response).to have_http_status(:success)
    end

    login(user.email, 'password123')
    get products_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it 'frees the slot again after the first session logs out' do
    first_session = ActionDispatch::Integration::Session.new(Rails.application)
    first_session.post user_session_path, params: { user: { email: user.email, password: 'password123' } }
    first_session.get products_path
    first_session.delete destroy_user_session_path

    login(user.email, 'password123')
    get products_path

    expect(response).to have_http_status(:success)
  end
end
