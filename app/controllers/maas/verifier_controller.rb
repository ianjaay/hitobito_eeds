# frozen_string_literal: true

# Endpoint de vérification QR pour les cartes membres.
class Maas::VerifierController < ApplicationController
  skip_authorization_check only: [:verify]

  def verify
    result = Maas::QrTokenService.verify(params[:token])

    if result
      member = result[:member]
      render json: {
        valid: result[:valid],
        member: {
          id: member.id,
          nom: member.last_name,
          prenom: member.first_name,
          branche: result[:branche]
        },
        adhesion: {
          statut: result[:statut],
          campagne: result[:campagne],
          expires_at: result[:expires_at]&.iso8601
        }
      }
    else
      render json: { valid: false, error: "Token invalide ou expiré" }, status: :not_found
    end
  end
end
