# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

CustomContent.seed(:key,
  {key: Event::ApprovalMailer::CONTENT_NEXT_APPROVERS,
   placeholders_required: "camp-name, applicant-name, layer, application-url"})

content = CustomContent.find_or_initialize_by(key: Event::ApprovalMailer::CONTENT_NEXT_APPROVERS)

CustomContent::Translation.seed(:custom_content_id, :locale,
  {custom_content_id: content.id,
   locale: "fr",
   label: "Notification : approbation requise pour un camp",
   subject: "[EEDS] Approbation requise : camp {camp-name}",
   body: <<~BODY},
     Bonjour,

     La candidature de {applicant-name} pour le camp « {camp-name} » est en
     attente de votre approbation au niveau {layer}.

     Vous pouvez consulter et traiter la candidature ici :
     {application-url}

     Merci,
     L'équipe EEDS
   BODY

  {custom_content_id: content.id,
   locale: "wo",
   label: "Bataaxal : nangu am na soxla ngir camp",
   subject: "[EEDS] Nangu am na soxla : camp {camp-name}",
   body: <<~BODY})
     Asalaa Maalekum,

     Kandidatuur bu {applicant-name} ngir camp « {camp-name }» mungi xaar
     sa nangu ci daara {layer}.

     Mën ngeen ko gis ak jëfandikoo ko fii :
     {application-url}

     Jërëjëf,
     Mboolo EEDS
   BODY

# --- Cotisation impayée : rappel par email ----------------------------------
CustomContent.seed(:key,
  {key: MembershipFeeMailer::CONTENT_UNPAID_REMINDER,
   placeholders_required: "recipient-name, year, branche, amount, group-name"})

reminder = CustomContent.find_or_initialize_by(key: MembershipFeeMailer::CONTENT_UNPAID_REMINDER)

CustomContent::Translation.seed(:custom_content_id, :locale,
  {custom_content_id: reminder.id,
   locale: "fr",
   label: "Rappel : cotisation EEDS impayée",
   subject: "[EEDS] Rappel cotisation {year}",
   body: <<~BODY},
     Bonjour {recipient-name},

     Notre système indique que votre cotisation EEDS pour l'année {year}
     ({branche}) d'un montant de {amount} n'a pas encore été enregistrée
     auprès de {group-name}.

     Merci de vous rapprocher de votre trésorier·ère pour régulariser votre
     situation.

     Fraternellement,
     L'équipe EEDS
   BODY

  {custom_content_id: reminder.id,
   locale: "wo",
   label: "Fàttali : pàcc EEDS bu fey wul",
   subject: "[EEDS] Fàttali pàcc {year}",
   body: <<~BODY})
     Asalaa Maalekum {recipient-name},

     Sunu sistem mu wone ne sa pàcc EEDS at {year} ({branche}) ngir {amount}
     du fey ci {group-name}.

     Lëkkalool ak sa caytukat ngir di ko fay.

     Ak jàmm,
     Mboolo EEDS
   BODY
