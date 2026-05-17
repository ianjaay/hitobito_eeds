# frozen_string_literal: true

module Sheet
  module Maas
    class PersonAdhesion < Sheet::Base
      self.parent_sheet = Sheet::Person
    end
  end
end
