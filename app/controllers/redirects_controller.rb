class RedirectsController < ApplicationController
  def show
    url = Url.find_by(short_code: params[:code])

    if url.nil?
      head :not_found
    elsif !url.redirectable?
      head :gone
    else
      redirect_to url.long_url, status: :found, allow_other_host: true
    end
  end
end
