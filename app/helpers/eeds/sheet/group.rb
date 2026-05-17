# frozen_string_literal: true

module Eeds::Sheet::Group
  extend ActiveSupport::Concern

  included do
    # Ajouter les chemins excel_imports comme alt: sur l'onglet Personnes
    people_tab = tabs.find { |t| t.label_key == "activerecord.models.person.other" }
    if people_tab
      people_tab.options[:alt] ||= []
      people_tab.options[:alt] << :new_group_excel_imports_path
      people_tab.options[:alt] << :preview_group_excel_imports_path
    end

    tab "eeds.group_progressions.tab",
        :group_group_progressions_path,
        if: :show

    tab "maas.nav.adhesions",
        :group_maas_adhesions_path,
        if: :show

    tab "finance.nav.finances",
        :group_finance_dashboard_index_path,
        if: :show
  end
end
