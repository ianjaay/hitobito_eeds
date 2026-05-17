# frozen_string_literal: true

# Téléchargement des reçus PDF.
# Accessible via /groups/:group_id/people/:person_id/finance_receipts/:id.pdf
class Finance::ReceiptsController < ApplicationController
  before_action :set_group_and_person
  authorize_resource class: Finance::Receipt

  def show
    @receipt = Finance::Receipt.find(params[:id])

    respond_to do |format|
      format.pdf do
        pdf_data = Finance::ReceiptPdf.new(@receipt).render
        send_data pdf_data,
                  filename: @receipt.pdf_filename,
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  private

  def set_group_and_person
    @group = ::Group.find(params[:group_id])
    @person = ::Person.find(params[:person_id])
  end
end
