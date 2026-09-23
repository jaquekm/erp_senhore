class RevenueEstimationsController < ApplicationController
  requires_feature :finance
  inherit_resources

  private

  def resource_params
    return [] if request.get?

    params.require(:revenue_estimation).permit(:date, :month, :average_ticket, :revenue, :quantity)
  end
end
