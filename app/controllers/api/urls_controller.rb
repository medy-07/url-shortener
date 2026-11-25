module Api
  class UrlsController < ApplicationController
    def create
      url = Shortener::Create.call(
        long_url: url_params[:long_url],
        alias_code: url_params[:alias],
        expires_at: url_params[:expires_at]
      )

      if url.persisted?
        render json: { short_url: "#{request.base_url}/#{url.short_code}" }, status: :created
      else
        render json: { errors: url.errors.to_hash(true) }, status: :unprocessable_content
      end
    end

    private

    def url_params
      params.permit(:long_url, :alias, :expires_at)
    end
  end
end
