# frozen_string_literal: true

require Rails.root.join('lib/lago_http_client/lago_http_client')

class SendWebhookJob < ApplicationJob
  queue_as 'webhook'

  # retry_on(
  #   LagoHttpClient::HttpError,
  #   wait: :exponentially_longer,
  #   attempts: ENV.fetch('LAGO_WEBHOOK_ATTEMPTS', 3).to_i,
  # )

  def perform(webhook_type, object, options = {}, webhook_id = nil)
    webhook_class = case webhook_type
                    when :invoice
                      Webhooks::InvoicesService
                    when :add_on
                      Webhooks::AddOnService
                    when :credit
                      Webhooks::PaidCreditService
                    when :event
                      Webhooks::EventService

                    # NOTE: Payment provider related webhooks
                    when :payment_provider_invoice_payment_error
                      Webhooks::PaymentProviders::InvoicePaymentFailureService
                    when :payment_provider_customer_created
                      Webhooks::PaymentProviders::CustomerCreatedService
                    when :payment_provider_customer_error
                      Webhooks::PaymentProviders::CustomerErrorService
                    when :payment_provider_customer_checkout_url
                      Webhooks::PaymentProviders::CustomerCheckoutService

                    # NOTE: This add the new way of managing webhooks
                    # A refact has to be done to improve webhooks management internally
                    when 'credit_note.created'
                      Webhooks::CreditNotes::CreatedService
                    when 'credit_note.generated'
                      Webhooks::CreditNotes::GeneratedService
                    when 'credit_note.provider_refund_failure'
                      Webhooks::CreditNotes::PaymentProviderRefundFailureService
                    when 'invoice.generated'
                      Webhooks::Invoices::GeneratedService
                    when 'invoice.drafted'
                      Webhooks::Invoices::DraftedService
                    when 'subscription.terminated'
                      Webhooks::Subscriptions::TerminatedService
                    else
                      raise(NotImplementedError)
    end

    webhook_class.new(object:, webhook_id:, options:).call
  end
end
