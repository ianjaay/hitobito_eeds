# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Notification des crises EEDS aux personnes responsables (Commissaires
# parents et Bureau Exécutif). Utilise `custom_content_mail` afin que les
# administrateurs puissent personnaliser le contenu (FR / WO).
class CrisisMailer < ApplicationMailer
  CONTENT_TRIGGERED    = "crisis_triggered"
  CONTENT_ACKNOWLEDGED = "crisis_acknowledged"
  CONTENT_COMPLETED    = "crisis_completed"

  def triggered(crisis)
    @crisis = crisis
    setup(crisis, CONTENT_TRIGGERED)
  end

  def acknowledged(crisis)
    @crisis = crisis
    setup(crisis, CONTENT_ACKNOWLEDGED)
  end

  def completed(crisis)
    @crisis = crisis
    setup(crisis, CONTENT_COMPLETED)
  end

  private

  def setup(crisis, content_key)
    recipients = recipient_emails_for(crisis)
    return ActionMailer::Base::NullMail.new if recipients.empty?

    custom_content_mail(recipients, content_key, placeholders(crisis))
  end

  # Adresses email des Commissaires/Chefs ayant `:approve_applications`
  # ou `:layer_and_below_full` sur les groupes ancêtres (district,
  # région, national) de la crise.
  def recipient_emails_for(crisis)
    g = crisis.group.reload
    ancestor_ids = Group.where("lft <= ? AND rgt >= ?", g.lft, g.rgt).pluck(:id)
    Person.joins(:roles).where(roles: {group_id: ancestor_ids})
      .where("roles.end_on IS NULL OR roles.end_on >= ?", Time.zone.today)
      .where.not(email: [nil, ""])
      .distinct.pluck(:email)
  end

  def placeholders(crisis)
    {
      "group-name"   => crisis.group.to_s,
      "kind"         => I18n.t("crises.kind.#{crisis.kind}", default: crisis.kind),
      "severity"     => I18n.t("crises.severity.#{crisis.severity}", default: crisis.severity),
      "creator-name" => crisis.creator.to_s,
      "description"  => crisis.description.to_s
    }
  end
end
