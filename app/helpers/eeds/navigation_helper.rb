# frozen_string_literal: true

module Eeds::NavigationHelper
  extend ActiveSupport::Concern

  included do
    def first_group_finance_or_root_path
      group = current_user&.groups&.first
      return root_path unless group

      group_finance_dashboard_index_path(group)
    end
  end
end
