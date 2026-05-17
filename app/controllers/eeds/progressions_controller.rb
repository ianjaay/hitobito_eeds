# frozen_string_literal: true

# Contrôleur de gestion des progressions pédagogiques EEDS.
# Imbriqué sous /groups/:group_id/people/:person_id/progressions
class Eeds::ProgressionsController < ApplicationController
  include Admin::FeatureAccessConcern

  DOMAINE_ORDER = %w[enab_physique enab_intellectuel donn_social yees_spirituel enab_affectif].freeze
  MENMEN_ICONS = {
    "men_communicateur" => "📡", "men_environnementaliste" => "🌿",
    "men_gestionnaire" => "📊", "men_secouriste" => "🏥",
    "men_citoyen" => "🏛️", "men_technologue" => "⚙️",
    "men_artiste" => "🎨", "men_leader" => "🌟"
  }.freeze

  before_action :set_group
  before_action :set_person
  before_action -> { check_feature_access!("progression") }
  before_action :set_progression, only: [:show, :edit, :update, :validate_progression, :request_rework, :start, :add_comment]
  before_action :authorize_action

  decorates :group, :person

  helper_method :group, :person, :entry

  # GET /groups/:group_id/people/:person_id/progressions
  def index
    # Branch detection — JEEGO are branch-specific, MËN-MËN are branch-agnostic
    @branche = detect_branche(@group)
    all_progs = progressions_scope.includes(:qualification_kind).to_a

    # JEEGO matrix: domaines (columns) × niveaux (rows)
    jeego_progs = all_progs.select { |p| p.qualification_kind.category == "jeego" }
    jeego_progs = jeego_progs.select { |p| p.qualification_kind.metadata&.dig("branche") == @branche } if @branche
    @jeego_matrix = {}
    (1..3).each do |niveau|
      @jeego_matrix[niveau] = {}
      DOMAINE_ORDER.each do |domaine|
        @jeego_matrix[niveau][domaine] = jeego_progs.find { |p|
          p.qualification_kind.metadata&.dig("domaine") == domaine &&
            p.qualification_kind.metadata&.dig("niveau") == niveau
        }
      end
    end

    # MËN-MËN badges
    @menmen_progressions = all_progs.select { |p| p.qualification_kind.category == "menmen" }

    # Stats
    total_jeego = jeego_progs.size
    validated_jeego = jeego_progs.count(&:validated?)
    in_progress_jeego = jeego_progs.count(&:in_progress?)
    validated_menmen = @menmen_progressions.count(&:validated?)
    menmen_total = @menmen_progressions.size.nonzero? || 8

    pct_jeego = total_jeego > 0 ? (validated_jeego * 100 / total_jeego) : 0
    pct_menmen = (validated_menmen * 100 / menmen_total)
    pct_global = (pct_jeego * 0.6 + pct_menmen * 0.4).round

    @stats = {
      total_jeego: total_jeego,
      validated_jeego: validated_jeego,
      in_progress_jeego: in_progress_jeego,
      validated_menmen: validated_menmen,
      menmen_total: menmen_total,
      pct_jeego: pct_jeego,
      pct_menmen: pct_menmen,
      pct_global: pct_global,
      current_level: validated_jeego >= 10 ? "Niveau 3" : validated_jeego >= 5 ? "Niveau 2" : "Niveau 1"
    }
  end

  # GET /groups/:group_id/people/:person_id/progressions/new
  def new
    @branche = detect_branche(@group)
    existing_qk_ids = progressions_scope.pluck(:qualification_kind_id)
    @available_jeego = QualificationKind.where(category: "jeego")
                        .where.not(id: existing_qk_ids)
    @available_menmen = QualificationKind.where(category: "menmen")
                         .where.not(id: existing_qk_ids)
    # JEEGO are branch-specific; MËN-MËN are branch-agnostic
    if @branche
      @available_jeego = @available_jeego.select { |qk| qk.metadata&.dig("branche") == @branche }
    end
    @progression = Eeds::Progression.new(person: @person, group: @group)
  end

  # POST /groups/:group_id/people/:person_id/progressions
  def create
    qk_ids = Array(params[:qualification_kind_ids]).map(&:to_i).reject(&:zero?)
    if qk_ids.empty?
      redirect_to new_group_person_progression_path(@group, @person),
                  alert: "Veuillez sélectionner au moins un JEEGO ou MËN-MËN"
      return
    end

    existing = progressions_scope.pluck(:qualification_kind_id)
    created = 0
    qk_ids.each do |qk_id|
      next if existing.include?(qk_id)
      qk = QualificationKind.find_by(id: qk_id)
      next unless qk && qk.category.in?(%w[jeego menmen])
      Eeds::Progression.create!(
        person: @person, group: @group, qualification_kind: qk,
        status: :not_started
      )
      created += 1
    end

    redirect_to group_person_progressions_path(@group, @person),
                notice: "#{created} progression(s) ajoutée(s)"
  end

  # GET /groups/:group_id/people/:person_id/progressions/:id
  def show
    @logs = @progression.logs.includes(:actor).order(created_at: :desc)
    @criteria = Eeds::Criterion.where(qualification_kind_id: @progression.qualification_kind_id) if @progression.qualification_kind.category == "menmen"
  end

  # GET /groups/:group_id/people/:person_id/progressions/:id/edit
  def edit
  end

  # PATCH /groups/:group_id/people/:person_id/progressions/:id
  def update
    if @progression.update(progression_params)
      redirect_to group_person_progression_path(@group, @person, @progression),
                  notice: "Progression mise à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # PATCH /groups/:group_id/people/:person_id/progressions/:id/start
  def start
    @progression.status = :in_progress
    if @progression.save
      redirect_to group_person_progressions_path(@group, @person),
                  notice: "Progression démarrée"
    else
      redirect_to group_person_progressions_path(@group, @person),
                  alert: @progression.errors.full_messages.join(", ")
    end
  end

  # PATCH /groups/:group_id/people/:person_id/progressions/:id/validate_progression
  def validate_progression
    @progression.assign_attributes(
      status: :validated,
      validated_by: current_user,
      validated_at: Time.current
    )
    if @progression.save
      redirect_to group_person_progression_path(@group, @person, @progression),
                  notice: "Progression validée — qualification attribuée"
    else
      redirect_to group_person_progression_path(@group, @person, @progression),
                  alert: @progression.errors.full_messages.join(", ")
    end
  end

  # POST /groups/:group_id/people/:person_id/progressions/:id/add_comment
  def add_comment
    comment = params[:comment].to_s.strip
    if comment.present?
      Eeds::ProgressionLog.create!(
        eeds_progression: @progression,
        actor: current_user,
        action: "comment",
        notes: comment
      )
      redirect_to group_person_progression_path(@group, @person, @progression),
                  notice: "Commentaire ajouté"
    else
      redirect_to group_person_progression_path(@group, @person, @progression),
                  alert: "Le commentaire ne peut pas être vide"
    end
  end

  # PATCH /groups/:group_id/people/:person_id/progressions/:id/request_rework
  def request_rework
    @progression.assign_attributes(
      status: :needs_work,
      notes: params[:eeds_progression]&.dig(:notes) || "Travail à revoir"
    )
    if @progression.save
      redirect_to group_person_progression_path(@group, @person, @progression),
                  notice: "Demande de reprise enregistrée"
    else
      redirect_to group_person_progression_path(@group, @person, @progression),
                  alert: @progression.errors.full_messages.join(", ")
    end
  end

  private

  def group
    @group
  end

  def person
    @person
  end

  def entry
    @progression
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_person
    @person = @group.people.find(params[:person_id])
  end

  def set_progression
    @progression = progressions_scope.find(params[:id])
  end

  def progressions_scope
    Eeds::Progression.for_person(@person.id).for_group(@group.id)
  end

  def progression_params
    params.require(:eeds_progression).permit(:notes, criteria_met: [])
  end

  def authorize_create
    authorize!(:update, @person)
  end

  def authorize_action
    authorize!(:show, @person)
  end

  def detect_branche(grp)
    map = { "Group::Woelfe" => "mbootaay", "Group::Pfadi" => "kayon",
            "Group::Pio" => "dental", "Group::Rover" => "galle" }
    current = grp
    while current
      return map[current.type] if map[current.type]
      current = current.parent
    end
    nil
  end
end
