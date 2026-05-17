# frozen_string_literal: true

# Génère un reçu PDF générique pour tout paiement du module Finance.
# Utilise Export::Pdf::Document (Prawn wrapper hitobito) avec polices NotoSans.
module Finance
  class ReceiptPdf
    MARGIN = 2.cm
    EEDS_PURPLE = "5D4296"
    EEDS_GOLD = "FCD116"

    def initialize(receipt)
      @receipt = receipt
      @obligation = receipt.obligation
      @payment = receipt.payment
      @person = receipt.person
      @fee = @obligation.activity_fee
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
      person_info
      payment_details
      summary_table
      footer

      @pdf
    end

    def header
      @pdf.fill_color EEDS_PURPLE
      @pdf.fill_rectangle [-MARGIN, @pdf.cursor + MARGIN], @pdf.bounds.width + 2 * MARGIN, 100
      @pdf.fill_color "FFFFFF"

      @pdf.move_down 10
      @pdf.text "ÉCLAIREURS ET ÉCLAIREUSES DU SÉNÉGAL", size: 11, style: :bold, align: :center
      @pdf.text "Gestion Financière des Activités", size: 9, align: :center
      @pdf.move_down 8
      @pdf.text "REÇU DE PAIEMENT", size: 18, style: :bold, align: :center
      @pdf.move_down 10

      @pdf.fill_color "000000"
      @pdf.move_down 15
    end

    def receipt_info
      data = [
        ["N° Reçu :", @receipt.numero],
        ["Date d'émission :", I18n.l(@receipt.emis_at.to_date, format: :long)],
        ["Activité :", activite_label],
        ["Catégorie :", @fee.categorie.humanize]
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

    def person_info
      @pdf.text "INFORMATIONS DU PARTICIPANT", size: 11, style: :bold, color: EEDS_PURPLE
      @pdf.move_down 6

      data = [
        ["Nom complet :", "#{@person.first_name} #{@person.last_name}"],
        ["Groupe :", @obligation.group&.name || "-"],
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
        ["Référence :", @payment&.reference_externe.presence || "-"],
        ["Commentaire :", @payment&.commentaire.presence || "-"]
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
      @pdf.text "RÉSUMÉ FINANCIER", size: 11, style: :bold, color: EEDS_PURPLE
      @pdf.move_down 6

      solde = @obligation.solde_restant

      data = [
        ["Description", "Montant"],
        [@fee.libelle, format_currency(@obligation.montant_total)],
        ["Total payé à ce jour", format_currency(@obligation.montant_paye)],
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
        @pdf.text "✓ INTÉGRALEMENT PAYÉ", size: 12, style: :bold, align: :center
        @pdf.fill_color "000000"
      end

      @pdf.move_down 15
    end

    def footer
      @pdf.move_down 20
      @pdf.stroke_color "DDDDDD"
      @pdf.stroke_horizontal_rule
      @pdf.move_down 10

      @pdf.fill_color "999999"
      @pdf.text "Ce reçu est généré automatiquement par la plateforme E-Gàlle des EEDS.", size: 8, align: :center
      @pdf.text "Document valable sans signature.", size: 8, align: :center
      @pdf.text "Reçu N° #{@receipt.numero} — Émis le #{I18n.l(@receipt.emis_at.to_date, format: :long)}", size: 8, align: :center
      @pdf.fill_color "000000"
    end

    def activite_label
      feeable = @fee.feeable
      if feeable.respond_to?(:name)
        feeable.name
      elsif feeable.respond_to?(:annee)
        "Campagne #{feeable.annee}"
      else
        @fee.libelle
      end
    end

    def group_hierarchy
      group = @obligation.group
      return "-" unless group

      parts = []
      current = group
      while current
        parts.unshift(current.name)
        current = current.parent
      end
      parts.join(" > ")
    end

    def format_currency(amount)
      "#{ActionController::Base.helpers.number_with_delimiter(amount.to_i, delimiter: "'")} FCFA"
    end
  end
end
