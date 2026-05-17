# frozen_string_literal: true

# Administration centrale des JEEGO et MËN-MËN.
# Accessible depuis les Paramètres (Settings).
# Permet de lister, créer, modifier et supprimer les QualificationKind
# de catégorie jeego/menmen ainsi que leurs critères.
class Eeds::AdminProgressionsController < ApplicationController
  BRANCHE_OPTIONS = [
    ["Mbootaay", "mbootaay"],
    ["Kayon", "kayon"],
    ["Dental", "dental"],
    ["Gàlle", "galle"]
  ].freeze

  DOMAINE_OPTIONS = [
    ["Enabilité physique", "enab_physique"],
    ["Enabilité intellectuelle", "enab_intellectuel"],
    ["Donnerie / Njaak social", "donn_social"],
    ["Yeesal / Spiritualité", "yees_spirituel"],
    ["Enabilité affective", "enab_affectif"]
  ].freeze

  MENMEN_KEYS = [
    ["Communicateur", "men_communicateur", "📡"],
    ["Environnementaliste", "men_environnementaliste", "🌿"],
    ["Gestionnaire", "men_gestionnaire", "📊"],
    ["Secouriste", "men_secouriste", "🏥"],
    ["Citoyen", "men_citoyen", "🏛️"],
    ["Technologue", "men_technologue", "⚙️"],
    ["Artiste", "men_artiste", "🎨"],
    ["Leader", "men_leader", "🌟"]
  ].freeze

  BRANCHE_COLORS = {
    "mbootaay" => "#FCD116", "kayon" => "#2ECC71",
    "dental" => "#0054A0", "galle" => "#E74C3C"
  }.freeze

  MENMEN_ICONS = {
    "men_communicateur" => "📡", "men_environnementaliste" => "🌿",
    "men_gestionnaire" => "📊", "men_secouriste" => "🏥",
    "men_citoyen" => "🏛️", "men_technologue" => "⚙️",
    "men_artiste" => "🎨", "men_leader" => "🌟"
  }.freeze

  before_action :set_qualification_kind, only: [:show, :edit, :update, :destroy]
  before_action :authorize_admin

  # GET /eeds_progression_badges
  def index
    all_qks = QualificationKind.where(category: %w[jeego menmen])
                                .includes(:translations)
                                .order(:category, :id)

    @jeego_by_branche = {}
    %w[mbootaay kayon dental galle].each do |br|
      @jeego_by_branche[br] = all_qks.select { |qk|
        qk.category == "jeego" && qk.metadata&.dig("branche") == br
      }
    end

    @menmen = all_qks.select { |qk| qk.category == "menmen" }

    @stats = {
      total_jeego: all_qks.count { |qk| qk.category == "jeego" },
      total_menmen: @menmen.size,
      branches: %w[mbootaay kayon dental galle].map { |br| [br, @jeego_by_branche[br].size] }.to_h
    }

    @criteria_counts = Eeds::Criterion.unscoped.group(:qualification_kind_id).count
    @usage_counts = Eeds::Progression.group(:qualification_kind_id).count
  end

  # GET /eeds_progression_badges/new
  def new
    @qualification_kind = QualificationKind.new
    @category = params[:category] || "jeego"
    @criteria = []
  end

  # POST /eeds_progression_badges
  def create
    category = params[:category]
    label = params[:label].to_s.strip
    description = params[:description].to_s.strip

    if label.blank?
      redirect_to new_eeds_progression_badge_path(category: category),
                  alert: "Le libellé est obligatoire"
      return
    end

    metadata = {}
    if category == "jeego"
      metadata[:branche] = params[:branche]
      metadata[:domaine] = params[:domaine]
      metadata[:niveau] = params[:niveau].to_i
      metadata[:prerequisite] = params[:prerequisite].presence
      key = "jeego_#{params[:branche]}_#{params[:domaine]}_n#{params[:niveau]}"
    else
      metadata[:key] = params[:menmen_key]
      key = params[:menmen_key]
    end

    if QualificationKind.exists?(key: key)
      redirect_to new_eeds_progression_badge_path(category: category),
                  alert: "Un #{category.upcase} avec cette clé existe déjà (#{key})"
      return
    end

    qk = QualificationKind.new(
      label: label,
      description: description,
      category: category,
      key: key,
      metadata: metadata
    )

    if qk.save
      qk.badge_image.attach(params[:badge_image]) if params[:badge_image].present?

      if category == "menmen" && params[:criteria_labels].present?
        params[:criteria_labels].each_with_index do |cl, i|
          next if cl.blank?
          Eeds::Criterion.create!(
            qualification_kind: qk,
            label: cl,
            position: i + 1
          )
        end
      end

      redirect_to eeds_progression_badge_path(qk),
                  notice: "#{category == 'jeego' ? 'JEEGO' : 'MËN-MËN'} « #{label} » créé"
    else
      redirect_to new_eeds_progression_badge_path(category: category),
                  alert: qk.errors.full_messages.join(", ")
    end
  end

  # GET /eeds_progression_badges/:id
  def show
    @criteria = Eeds::Criterion.where(qualification_kind_id: @qualification_kind.id).order(:position)
    @usage_count = Eeds::Progression.where(qualification_kind_id: @qualification_kind.id).count
    @status_counts = Eeds::Progression.where(qualification_kind_id: @qualification_kind.id)
                                       .group(:status).count
  end

  # GET /eeds_progression_badges/:id/edit
  def edit
    @category = @qualification_kind.category
    @criteria = Eeds::Criterion.where(qualification_kind_id: @qualification_kind.id).order(:position)
  end

  # PATCH /eeds_progression_badges/:id
  def update
    label = params[:label].to_s.strip
    description = params[:description].to_s.strip

    if label.blank?
      redirect_to edit_eeds_progression_badge_path(@qualification_kind),
                  alert: "Le libellé est obligatoire"
      return
    end

    metadata = @qualification_kind.metadata || {}
    if @qualification_kind.category == "jeego"
      metadata["branche"] = params[:branche] if params[:branche].present?
      metadata["domaine"] = params[:domaine] if params[:domaine].present?
      metadata["niveau"] = params[:niveau].to_i if params[:niveau].present?
      metadata["prerequisite"] = params[:prerequisite].presence
    end

    @qualification_kind.assign_attributes(
      label: label,
      description: description,
      metadata: metadata
    )

    if @qualification_kind.save
      @qualification_kind.badge_image.attach(params[:badge_image]) if params[:badge_image].present?

      if @qualification_kind.category == "menmen" && params[:criteria_labels].present?
        existing_ids = params[:criteria_ids]&.map(&:to_i) || []
        Eeds::Criterion.where(qualification_kind_id: @qualification_kind.id)
                       .where.not(id: existing_ids).destroy_all

        params[:criteria_labels].each_with_index do |cl, i|
          next if cl.blank?
          cid = existing_ids[i]
          if cid && cid > 0
            c = Eeds::Criterion.find_by(id: cid)
            c&.update(label: cl, position: i + 1)
          else
            Eeds::Criterion.create!(
              qualification_kind: @qualification_kind,
              label: cl,
              position: i + 1
            )
          end
        end
      end

      redirect_to eeds_progression_badge_path(@qualification_kind),
                  notice: "#{@qualification_kind.category == 'jeego' ? 'JEEGO' : 'MËN-MËN'} mis à jour"
    else
      redirect_to edit_eeds_progression_badge_path(@qualification_kind),
                  alert: @qualification_kind.errors.full_messages.join(", ")
    end
  end

  # DELETE /eeds_progression_badges/:id
  def destroy
    label = @qualification_kind.label
    cat = @qualification_kind.category
    usage = Eeds::Progression.where(qualification_kind_id: @qualification_kind.id).count
    if usage > 0
      redirect_to eeds_progression_badge_path(@qualification_kind),
                  alert: "Impossible de supprimer : #{usage} progression(s) utilisent ce badge"
      return
    end

    Eeds::Criterion.where(qualification_kind_id: @qualification_kind.id).destroy_all
    @qualification_kind.destroy

    redirect_to eeds_progression_badges_path,
                notice: "#{cat == 'jeego' ? 'JEEGO' : 'MËN-MËN'} « #{label} » supprimé"
  end

  private

  def set_qualification_kind
    @qualification_kind = QualificationKind.find(params[:id])
  end

  def authorize_admin
    authorize!(:index, QualificationKind)
  end
end
