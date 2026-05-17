# frozen_string_literal: true

# Téléchargement des reçus de cotisation en PDF.
# GET /groups/:group_id/people/:person_id/maas_receipts/:id.pdf
class Maas::ReceiptsController < ApplicationController
  before_action :set_group
  before_action :set_person
  before_action :set_receipt

  def show
    authorize!(:show, @person)

    respond_to do |format|
      format.pdf do
        pdf_data = Maas::ReceiptPdf.new(@receipt).render
        send_data pdf_data,
                  filename: @receipt.pdf_filename,
                  type: "application/pdf",
                  disposition: "inline"
      end
      format.html { redirect_to group_person_maas_adhesions_path(@group, @person) }
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_person
    @person = Person.find(params[:person_id])
  end

  def set_receipt
    @receipt = Maas::Receipt.where(member_id: @person.id).find(params[:id])
  end
end
