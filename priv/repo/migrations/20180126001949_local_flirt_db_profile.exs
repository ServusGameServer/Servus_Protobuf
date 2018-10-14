defmodule Servus.Repo.Migrations.LocalFlirtDbProfile do
  use Ecto.Migration

  def change do
    create table("LocalFlirtDbCampaign_User_Profile") do
      add(:loginID_id, references("playerLogin"))
      add(:gender, :integer)
      add(:age, :integer)
      add(:displayProfileName, :string)
      timestamps()
    end
    create unique_index("LocalFlirtDbCampaign_User_Profile", :loginID_id)
  end
end
