# frozen_string_literal: true

class GiftCardsController < ApplicationController
  before_action :set_country_and_footprint_average, only: [:index]
  before_action :validate_months_parameter, only: [:new]
  before_action :clear_gift_card_in_checkout, except: [:create]
  before_action :set_canonical, only: [:new]
  after_action :set_gift_card_in_checkout, only: [:create]

  def index
    @gift_cards = {
      1 => GiftCard.new(number_of_months: 1, currency: current_region.currency, country: @country),
      3 => GiftCard.new(number_of_months: 3, currency: current_region.currency, country: @country),
      6 => GiftCard.new(number_of_months: 6, currency: current_region.currency, country: @country),
      12 => GiftCard.new(number_of_months: 12, currency: current_region.currency, country: @country)
    }
  end

  def new
    @gift_card = new_gift_card_from_params
  end

  def create
    @gift_card = gift_card_from_form_fields

    render_validation_errors_json && return unless @gift_card.valid?(:without_payment_intent_id)

    @gift_card.create_payment_intent
    @gift_card.save!

    render_payment_intent_json
  end

  def thank_you
    @gift_card = GiftCard.find_by_key!(params[:key])

    render_not_found unless @gift_card.finalize
  end

  protected

  def canonical_query_params
    super + [:subscription_months_to_gift]
  end

  private

  def render_payment_intent_json
    render json: {
      payment_intent_client_secret: @gift_card.payment_intent.client_secret,
      success_url: thank_you_gift_card_path(@gift_card)
    }
  end

  def render_validation_errors_json
    render(
      status: :bad_request,
      json: { error: { message: @gift_card.errors.full_messages.join(', ') } }
    )
  end

  def validate_months_parameter
    redirect_to gift_cards_path unless [1, 3, 6, 12].include?(params[:subscription_months_to_gift].to_i)
  end

  def new_gift_card_from_params
    GiftCard.new(
      number_of_months: params[:subscription_months_to_gift].to_i,
      currency: current_region.currency,
      country: params[:country]
    )
  end

  def gift_card_from_form_fields
    attributes = params.require(:gift_card).permit(
      :number_of_months, :customer_email, :message, :payment_intent_id, :country
    ).to_h.symbolize_keys

    # Don't create duplicate GiftCards if previous attempts weren't yet finalized
    if (gift_card = gift_card_in_checkout)
      gift_card.attributes = gift_card.attributes.merge(attributes)
      return gift_card
    end

    GiftCard.new(currency: current_region.currency, **attributes)
  end

  def gift_card_in_checkout
    return unless session[:gift_card_in_checkout].present?

    GiftCard.where(id: session[:gift_card_in_checkout], paid_at: nil).first
  end

  def set_gift_card_in_checkout
    session[:gift_card_in_checkout] = @gift_card.id
  end

  def clear_gift_card_in_checkout
    session[:gift_card_in_checkout] = nil
  end

  def set_country_and_footprint_average
    @country =
      ISO3166::Country.new(params[:country]) ||
      visitor_country ||
      ISO3166::Country.new('US')
    @footprint_average = LifestyleFootprintAverage.find_by_country(@country)
  end

  def set_canonical
    set_meta_tags(canonical: gift_cards_url)
  end
end
