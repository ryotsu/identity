defmodule Identity.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:contacts) do
      add :phone, :string
      add :email, :citext
      add :is_primary, :boolean, default: false, null: false
      add :linked, references(:contacts, on_delete: :nothing)

      timestamps()
    end

    create index(:contacts, [:linked])
    create index(:contacts, [:phone])
    create index(:contacts, [:email])
  end
end
