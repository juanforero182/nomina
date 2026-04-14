class ConversionLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    logs = ConversionLog.includes(:user, :company).order(created_at: :desc)
    @pagy, @conversion_logs = pagy(logs, limit: 20)
  end
end
