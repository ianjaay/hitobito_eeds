# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Concern injecté dans `Event::Application` pour câbler le workflow
# d'approbation EEDS : association `has_many :approvals`, helper
# `next_open_approval`, et auto-construction de la première Approval requise
# lorsque la candidature à un camp est créée.
module Eeds::EventApplication
  extend ActiveSupport::Concern

  included do
    has_many :approvals, class_name: "Event::Approval", dependent: :destroy

    after_commit :initialize_approval, on: :create
  end

  # Première approval encore en attente (selon l'ordre canonique des couches).
  def next_open_approval
    approvals.where(approved: false, rejected: false).order_by_layer.first
  end

  private

  def initialize_approval
    return unless participation
    return unless participation.event.is_a?(Event::Camp)

    participation.reload if participation.persisted?
    Eeds::EventApprover.new(participation).request_approvals
  end
end
