# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module Export::Tabular::MembershipFees
  class List < Export::Tabular::Base
    self.model_class = ::MembershipFee
    self.row_class   = Export::Tabular::MembershipFees::Row

    def attributes
      [:year, :branche, :person_name, :group_name, :amount, :currency,
        :status, :paid_at, :payment_method, :reference]
    end
  end
end
