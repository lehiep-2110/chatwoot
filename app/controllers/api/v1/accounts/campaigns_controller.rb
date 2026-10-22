class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def create
    head :gone
  end

  def update
    head :gone
  end

  def destroy
    head :gone
  end
end
