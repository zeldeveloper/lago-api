# frozen_string_literal: true

class Webhook < ApplicationRecord
  belongs_to :organization
  belongs_to :object, polymorphic: true

  STATUS = %i[pending succeeded failed].freeze

  enum status: STATUS
end
