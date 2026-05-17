# frozen_string_literal: true

require "jwt"

# Génère et vérifie les tokens JWT de carte membre.
module Maas
  class QrTokenService
    ALGORITHM = "HS256"

    def self.generate(subscription)
      payload = {
        sub: subscription.id,
        member_id: subscription.member_id,
        branche: subscription.membership_plan&.branche,
        statut: subscription.statut,
        campagne: subscription.membership_campaign&.annee,
        exp: subscription.expires_at&.to_i || 1.year.from_now.to_i
      }

      token = JWT.encode(payload, secret_key, ALGORITHM)
      subscription.update_columns(qr_token: token)
      token
    end

    def self.verify(token)
      payload = JWT.decode(token, secret_key, true, algorithm: ALGORITHM).first
      subscription = Maas::MembershipSubscription.find_by(id: payload["sub"])

      return nil unless subscription
      return nil if subscription.qr_token != token

      {
        valid: subscription.statut == "valide",
        subscription: subscription,
        member: subscription.member,
        statut: subscription.statut,
        branche: payload["branche"],
        campagne: payload["campagne"],
        expires_at: Time.at(payload["exp"])
      }
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def self.secret_key
      Rails.application.secret_key_base[0..31]
    end
  end
end
