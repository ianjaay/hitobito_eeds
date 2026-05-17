# frozen_string_literal: true

module Eeds::Sheet::Person
  extend ActiveSupport::Concern

  included do
    tab "eeds.progressions.tab",
        :group_person_progressions_path,
        if: :show

    tab "maas.person_adhesions.tab",
        :group_person_maas_adhesions_path,
        if: :show

    tab "finance.person_finances.tab",
        :group_person_finances_path,
        if: :show
  end
end
