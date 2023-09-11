defmodule Identity.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :phone, :string, default: nil
    field :email, :string, default: nil
    field :is_primary, :boolean, default: false
    belongs_to :primary, Identity.Contact, foreign_key: :linked

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:phone, :email, :is_primary])
    |> validate_phone_or_email_required()
  end

  defp validate_phone_or_email_required(changeset) do
    missing_fields = Enum.filter([:phone, :email], &field_missing?(changeset, &1))

    case missing_fields do
      [_, _] ->
        add_error(changeset, :contact, "`email` and `phone` can't both be blank")

      _ ->
        changeset
    end
  end
end
