defmodule Servus.Repo.Migrations.CreatePlayerLogin do
  use Ecto.Migration

  def change do
  	create table("playerLogin") do
      add(:nickname, :string)
      add(:internalPlayerKey, :bigint, unique: true)
      add(:email, :string, unique: true)
      add(:passwortMD5Hash, :string)
      add(:facebook_id, :string, unique: true)
      add(:facebook_token, :string)
      add(:facebook_token_expires, :bigint)
      add(:confirmed, :boolean, default: false)
      timestamps()
    end
    create unique_index("playerLogin", [:internalPlayerKey])
    create unique_index("playerLogin", [:email])
    create unique_index("playerLogin", [:facebook_id])
  end
end
