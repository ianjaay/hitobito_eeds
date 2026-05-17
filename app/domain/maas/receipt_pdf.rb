# frozen_string_literal: true

# Génère un reçu PDF pour un paiement de cotisation.
# Utilise Export::Pdf::Document (Prawn wrapper hitobito) avec polices NotoSans.
module Maas
  class ReceiptPdf
    MARGIN = 2.cm
    EEDS_PURPLE = "5D4296"
    EEDS_GOLD = "FCD116"

    BRANCHE_COLORS = {
      "Mbootaay" => "FCD116", "Kayon" => "2ECC71", "Dental" => "0054A0",
      "Galle" => "E74C3C", "National" => "5D4296", "Gilwell" => "8B4513"
    }.freeze

    def initialize(receipt)
      @receipt = receipt
      @subscription = receipt.membership_subscription
      @transaction = receipt.payment_transaction
      @member = receipt.member
      @campaign = @subscription.membership_campaign
      @plan = @subscription.membership_plan
    end

    def render
      build_pdf.render
    end

    private

    def build_pdf
      doc = Export::Pdf::Document.new(margin: MARGIN)
      @pdf = doc.pdf

      header
      receipt_info
      member_info
      payment_details
      summary_table
      footer

      @pdf
    end

    def header
      @pdf.fill_color EEDS_PURPLE
      @pdf.fill_rectangle [- MARGIN, @pdf.cursor + MARGIN], @pdf.bounds.width + 2 * MARGIN, 100
      @pdf.fill_color "FFFFFF"

      @pdf.move_down 10
      @pdf.text "ÉCLAIREURS ET ÉCLAIREUSES DU SÉNÉGAL", size: 11, style: :bold, align: :center
      @pdf.text "Cotisations EEDS", size: 9, align: :center
      @pdf.move_down 8
      @pdf.text "REÇU DE PAIEMENT", size: 18, style: :bold, align: :center
      @pdf.move_down 10

      @pdf.fill_color "000000"
      @pdf.move_down 15
    end

    def receipt_info
      branche_color = BRANCHE_COLORS[@plan&.branche] || EEDS_PURPLE

      data = [
        ["N° Reçu :", @receipt.numero],
        ["Date d'émission :", I18n.l(@receipt.emis_at.to_date, format: :long)],
        ["Campagne :", "#{@campaign.annee}"],
        ["Branche :", @plan&.branche || "-"]
      ]

      @pdf.table(data, width: @pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = [4, 8]
        t.column(0).font_style = :bold
        t.column(0).width = 160
        t.column(0).text_color = EEDS_PURPLE
      end

      @pdf.move_down 10
      @pdf.stroke_color EEDS_GOLD
      @pdf.stroke_horizontal_rule
      @pdf.stroke_color "000000"
      @pdf.move_down 15
    end

    def member_info
      @pdf.text "INFORMATIONS DU MEMBRE", size: 11, style: :bold, color: EEDS_PURPLE
      @pdf.move_down 6

      data = [
        ["Nom complet :", "#{@member.first_name} #{@member.last_name}"],
        ["Groupe :", @subscription.group&.name || "-"],
        ["Structure :", group_hierarchy]
      ]

      @pdf.table(data, width: @pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = [3, 8]
        t.column(0).font_style = :bold
        t.column(0).width = 160
      end

      @pdf.move_down 15
    end

    def payment_details
      @pdf.text "DÉTAILS DU PAIEMENT", size: 11, style: :bold, color: EEDS_PURPLE
      @pdf.move_down 6

      data = [
        ["Montant payé :", format_currency(@receipt.montant)],
        ["Modalité :", @receipt.modalite || "Cash"],
        ["Référence :", @transaction&.reference_manuelle.presence || "-"],
        ["Notes :", @transaction&.notes.presence || "-"]
      ]

      @pdf.table(data, width: @pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = [3, 8]
        t.column(0).font_style = :bold
        t.column(0).width = 160
      end

      @pdf.move_down 15
    end

    def summary_table
      @pdf.text "RÉSUMÉ DE L'ADHÉSION", size: 11, style: :bold, color: EEDS_PURPLE
      @pdf.move_down 6

      solde = @subscription.solde_restant

      data = [
        ["Description", "Montant"],
        ["Cotisation #{@plan&.branche} — Campagne #{@campaign.annee}", format_currency(@subscription.montant_total)],
        ["Total payé à ce jour", format_currency(@subscription.montant_paye)],
        ["Solde restant", format_currency(solde)]
      ]

      @pdf.table(data, width: @pdf.bounds.width) do |t|
        t.cells.padding = [6, 10]
        t.cells.borders = [:bottom]
        t.cells.border_color = "DDDDDD"
        t.row(0).font_style = :bold
        t.row(0).background_color = "F5F3FA"
        t.row(0).text_color = EEDS_PURPLE
        t.column(1).align = :right
        t.row(-1).font_style = :bold
        t.row(-1).text_color = solde.zero? ? "28A745" : "DC3545"
      end

      if solde.zero?
        @pdf.move_down 10
        @pdf.fill_color "28A745"
        @pdf.text "✓ ADHÉSION INTÉGRALEMENT PAYÉE", size: 12, style: :bold, align: :center
        @pdf.fill_color "000000"
      end

      if @subscription.assurance_active?
        @pdf.move_down 6
        @pdf.text "Assurance scoute incluse", size: 9, style: :bold, align: :center, color: "17A2B8"
      end

      @pdf.move_down 20
    end

    def footer
      @pdf.stroke_color EEDS_PURPLE
      @pdf.stroke_horizontal_rule
      @pdf.stroke_color "000000"
      @pdf.move_down 10

      @pdf.text "Ce reçu a été généré automatiquement par la plateforme E-Gàlle.", size: 8, color: "999999", align: :center
      @pdf.text "Éclaireurs et Éclaireuses du Sénégal — www.eeds.sn", size: 8, color: "999999", align: :center
      @pdf.text "Document émis le #{I18n.l(Time.current.to_date, format: :long)}", size: 8, color: "999999", align: :center
    end

    def format_currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, unit: "FCFA ", separator: ",", delimiter: ".")
    end

    def group_hierarchy
      group = @subscription.group
      return "-" unless group

      parts = []
      current = group
      while current
        parts.unshift(current.name)
        current = current.parent
      end
      parts.join(" > ")
    end
  end
end
