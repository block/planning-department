class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_create :assign_uuid, if: -> { id.blank? }

  private

  def assign_uuid
    self.id = SecureRandom.uuid
  end
end
