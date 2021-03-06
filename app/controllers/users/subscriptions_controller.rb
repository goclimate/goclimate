# frozen_string_literal: true

module Users
  class SubscriptionsController < ApplicationController
    before_action :authenticate_user!
    before_action :notice_updated, only: [:show]
    before_action :set_subscription_manager

    def show
      @customer_payment_method = customer_payment_method
      @current_plan = current_user.current_plan
      @available_plans = Subscriptions::Plan.available_plans(customer_currency, @current_plan)
    end

    def update
      new_plan = Subscriptions::Plan.for_price(Money.from_amount(plan_param, customer_currency))
                                    .retrieve_or_create_stripe_plan

      if @manager.subscription.present?
        @manager.update(new_plan, params[:payment_method_id])
      else
        @manager.sign_up(new_plan, params[:payment_method_id])
      end

      if @manager.errors.any?
        render_bad_request(@manager.errors)
      elsif @manager.confirmation_required?
        render_confirmation_required
      else
        render_successful_update
      end
    end

    def destroy
      return redirect_to action: :show if @manager.subscription.nil?

      SubscriptionCancellationFeedback.create(cancellation_reason_params)
      @manager.cancel

      flash[:notice] = I18n.t('views.subscriptions.cancel.cancellation_successful')
      redirect_to action: :show
    end

    private

    # Because we can't always be sure an update is complete before client side
    # things happen, let the client redirect to a query param to set the notice
    # in those cases.
    def notice_updated
      return unless params[:updated] == '1'

      flash[:notice] = I18n.t('your_payment_details_have_been_updated')
      redirect_to user_subscription_path
    end

    def set_subscription_manager
      @manager = Subscriptions::StripeSubscriptionManager.new(current_user)
    end

    def render_successful_update
      flash[:notice] = I18n.t('your_payment_details_have_been_updated')
      render json: { next_step: 'redirect', success_url: user_subscription_path }, status: :ok
    end

    def render_confirmation_required
      render json: {
        next_step: 'confirmation_required',
        intent_type: @manager.intent_to_confirm.object,
        intent_client_secret: @manager.intent_to_confirm.client_secret,
        success_url: user_subscription_path(updated: 1)
      }, status: :ok
    end

    def render_bad_request(errors)
      render json: { error: errors }, status: :bad_request
    end

    def customer_currency
      Currency.from_iso_code(current_user.stripe_customer.currency) || current_region.currency
    end

    def customer_payment_method
      if (payment_method_id = current_user.stripe_customer.invoice_settings&.default_payment_method)
        Stripe::PaymentMethod.retrieve(payment_method_id)
      elsif (source_id = current_user.stripe_customer.default_source)
        current_user.stripe_customer.sources.find { |s| s.id == source_id }
      end
    end

    def plan_param
      params[:user][:plan]
    end

    def cancellation_reason_params
      {
        subscribed_at: Time.at(@manager.subscription.start_date),
        reason:
          if params[:cancellation_reason] == 'other'
            params[:cancellation_reason_other_text]
          else
            params[:cancellation_reason]
          end
      }
    end
  end
end
