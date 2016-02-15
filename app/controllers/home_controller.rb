class HomeController < ApplicationController
  before_filter :ensure_signup_complete, only: [:new, :create, :update, :destroy]
  def index
  end
end